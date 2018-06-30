import Qfit.Plug.ParametersValidation

defmodule Qfit.Plug.ParametersValidation.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Qfit.Plug.ParametersValidation

  test "success when parameter exists" do
    [private: %{validator: fields}] = validate(%{field_1: :string})

    assert %{body_params: %{field_1: "hello"}} =
      conn("POST", "/", %{"field_1" => "hello"})
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
  end

  test "error when parameter missing" do
    [private: %{validator: fields}] = validate(%{field_1: :string})

    assert %{state: :sent, status: 400} =
      conn("POST", "/", %{})
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
  end

  test "error when parameter type mismatch" do
    [private: %{validator: fields}] = validate(%{field_1: :string})

    assert %{state: :sent, status: 400} =
      conn("POST", "/", %{"field_1": 1})
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
  end

  test "skip when no validate" do
    assert %{state: :unset, body_params: %{"field_1" => 1}} =
      conn("POST", "/", %{"field_1": 1})
        |> parameters_validation(nil)
  end

  test "only in post" do
    [private: %{validator: fields}] = validate(%{field_1: :string})

    assert_raise RuntimeError, fn ->
      conn("GET", "/")
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("OPTIONS", "/")
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("PUT", "/")
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("PATCH", "/")
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("DELETE", "/")
        |> put_private(:validator, fields)
        |> parameters_validation(nil)
      end
  end
end
