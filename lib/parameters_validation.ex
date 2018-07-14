import Plug.Conn
require Logger

defmodule Qfit.Plug.ParametersValidation do
  @moduledoc false

  def validate(%{} = types) do
    validate(types, optionals: [])
  end

  def validate(%{} = types, optionals: optionals) do
    keys = Map.keys(types)
    required = keys |> Enum.filter(fn key -> key not in optionals end)
    default = optionals |> Map.new(fn key -> {key, nil} end)

    [private: %{validator: {types, keys, required, default}}]
  end

  def parameters_validation(%{method: "POST", private: %{validator: validator}} = conn, _opts) do
    body_params = conn.body_params

    case use_validator(body_params, validator) do
      :skipped ->
        conn

      {:ok, body_params} ->
        %{conn | body_params: body_params}

      {:error, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{errors: errors}))
        |> halt
    end
  end

  def parameters_validation(%{private: %{validator: _}} = conn, _opts) do
    Logger.error(
      "Can only use validate() with a POST request, path: (#{conn.method}) #{conn.request_path}"
    )

    raise "can only use validate() with a POST request"
  end

  def parameters_validation(conn, _opts) do
    conn
  end

  defp use_validator(body_params, {types, keys, required, default}) do
    changeset = default_validator(body_params, types, keys, required)

    if changeset.valid? do
      {:ok, default |> Map.merge(changeset.changes)}
    else
      {:error, error_messages(changeset)}
    end
  end

  defp use_validator(_, _) do
    :skipped
  end

  defp default_validator(body_params, types, keys, required) do
    {body_params, types}
    |> Ecto.Changeset.cast(body_params, keys)
    |> Ecto.Changeset.validate_required(required)
  end

  defp error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
