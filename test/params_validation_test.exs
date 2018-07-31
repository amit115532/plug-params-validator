import ParamsValidation

defmodule ParamsValidation.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest ParamsValidation

  test "get with valid parameters" do
    [private: %{params_validator: validator}] = expect(path_params: %{path_param: :string})

    conn = conn("GET", "/:path_param")
    conn = %{conn | path_params: %{path_param: "lol"}}

    assert %{status: nil} =
             conn |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "get with invalid parameters" do
    [private: %{params_validator: validator}] = expect(path_params: %{path_param: :string})

    conn = conn("GET", "/:path_param")
    conn = %{conn | path_params: %{path_param: 10}}

    assert %{state: :sent, status: 400} =
             conn |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "post with with mixed parameters" do
    [private: %{params_validator: validator}] =
      expect(
        path_params: %{path_param: :string},
        body_params: %{body_param: :integer, optional_body_param: :string},
        optional_body_params: [:optional_body_param]
      )

    conn = conn("POST", "/:path_param", %{body_param: 10})
    conn = %{conn | path_params: %{path_param: "10"}}

    assert %{state: :unset, body_params: %{body_param: 10, optional_body_param: nil}} =
             conn |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "post with with invalid mixed parameters" do
    [private: %{params_validator: validator}] =
      expect(
        path_params: %{path_param: :string},
        body_params: %{body_param: :integer, optional_body_param: :string},
        optional_body_params: [:optional_body_param]
      )

    conn = conn("POST", "/:path_param", %{body_param_1: "10"})
    conn = %{conn | path_params: %{path_param: "10"}}

    assert %{state: :sent, status: 400} =
             conn |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "post with with invalid param and optional param" do
    [private: %{params_validator: validator}] =
      expect(
        path_params: %{path_param: :string},
        body_params: %{body_param: :string, optional_body_param: :string},
        optional_body_params: [:optional_body_param]
      )

    conn = conn("POST", "/:path_param", %{body_param: 10})
    conn = %{conn | path_params: %{path_param: "10"}}

    assert %{state: :sent, status: 400} =
             conn |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "success when parameter exists" do
    [private: %{params_validator: validator}] = expect(body_params: %{field_1: :string})

    assert %{body_params: %{field_1: "hello"}} =
             conn("POST", "/", %{"field_1" => "hello"})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "success when optional not given" do
    [private: %{params_validator: validator}] =
      expect(body_params: %{field_1: :string}, optional_body_params: [:field_1])

    assert %{state: :unset, body_params: %{field_1: nil}} =
             conn("POST", "/", %{})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "success when optional and not optional given" do
    [private: %{params_validator: validator}] =
      expect(body_params: %{field_1: :string, field_2: :string}, optional_body_params: [:field_1])

    assert %{state: :unset, body_params: %{field_1: nil, field_2: "hello"}} =
             conn("POST", "/", %{"field_2" => "hello"})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "optional given and added to body params" do
    [private: %{params_validator: validator}] =
      expect(body_params: %{field_1: :string}, optional_body_params: [:field_1])

    assert %{state: :unset, body_params: %{field_1: "field_1"}} =
             conn("POST", "/", %{"field_1" => "field_1"})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "error when parameter missing" do
    [private: %{params_validator: validator}] = expect(body_params: %{field_1: :string})

    assert %{state: :sent, status: 400} =
             conn("POST", "/", %{})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "error when parameter type mismatch" do
    [private: %{params_validator: validator}] = expect(body_params: %{field_1: :string})

    assert %{state: :sent, status: 400} =
             conn("POST", "/", %{field_1: 1})
             |> put_private(:params_validator, validator)
             |> call(log_errors?: false)
  end

  test "skip when no validate" do
    assert %{state: :unset, body_params: %{"field_1" => 1}} =
             conn("POST", "/", %{field_1: 1})
             |> call(log_errors?: false)
  end

  test "query params" do
    [private: %{params_validator: validator}] = expect(query_params: %{field_1: :integer})
    parser_opts = Plug.Parsers.init(parsers: [:json, :urlencoded], json_decoder: Poison)
    assert %{state: :unset, query_params: %{field_1: 1}} =
             conn("POST", "/test?field_1=1", nil)
             |> put_private(:params_validator, validator)
             |> Plug.Parsers.call(parser_opts)
             |> call(log_errors?: false)
  end

  test "optional query params" do
    [private: %{params_validator: validator}] = expect(query_params: %{field_1: :integer})
    parser_opts = Plug.Parsers.init(parsers: [:json, :urlencoded], json_decoder: Poison)
    assert %{state: :unset, query_params: %{field_1: nil}} =
             conn("POST", "/test", nil)
             |> put_private(:params_validator, validator)
             |> Plug.Parsers.call(parser_opts)
             |> call(log_errors?: false)
  end
end
