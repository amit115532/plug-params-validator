import Qfit.Plug.ParametersValidation

defmodule Qfit.Plug.ParametersValidation.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Qfit.Plug.ParametersValidation

  test "success when parameter exists" do
    [private: %{validator: validator}] = validate(%{field_1: :string})

    assert %{body_params: %{field_1: "hello"}} =
      conn("POST", "/", %{"field_1" => "hello"})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "success when optional not given" do
    [private: %{validator: validator}] = validate(%{field_1: :string}, optionals: [:field_1])

    assert %{state: :unset, body_params: %{field_1: nil}} =
      conn("POST", "/", %{})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "success when optional and not optional given" do
    [private: %{validator: validator}] = validate(%{field_1: :string, field_2: :string}, optionals: [:field_1])

    assert %{state: :unset, body_params: %{field_1: nil, field_2: "hello"}} =
      conn("POST", "/", %{"field_2" => "hello"})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "optional given and added to body params" do
    [private: %{validator: validator}] = validate(%{field_1: :string}, optionals: [:field_1])

    assert %{state: :unset, body_params: %{field_1: "field_1"}} =
      conn("POST", "/", %{"field_1" => "field_1"})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "error when parameter missing" do
    [private: %{validator: validator}] = validate(%{field_1: :string})

    assert %{state: :sent, status: 400} =
      conn("POST", "/", %{})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "error when parameter type mismatch" do
    [private: %{validator: validator}] = validate(%{field_1: :string})

    assert %{state: :sent, status: 400} =
      conn("POST", "/", %{"field_1": 1})
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
  end

  test "skip when no validate" do
    assert %{state: :unset, body_params: %{"field_1" => 1}} =
      conn("POST", "/", %{"field_1": 1})
        |> parameters_validation(nil)
  end

  test "only in post" do
    [private: %{validator: validator}] = validate(%{field_1: :string})

    assert_raise RuntimeError, fn ->
      conn("GET", "/")
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("OPTIONS", "/")
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("PUT", "/")
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("PATCH", "/")
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
      end

    assert_raise RuntimeError, fn ->
      conn("DELETE", "/")
        |> put_private(:validator, validator)
        |> parameters_validation(nil)
      end
  end
end
