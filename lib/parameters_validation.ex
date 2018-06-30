import Plug.Conn
require Logger

defmodule Qfit.Plug.ParametersValidation do
  @moduledoc false

  def validate(%{} = types) do
    [private: %{validator: types}]
  end

  def validate(validator) do
    [private: %{validator: validator}]
  end

  def parameters_validation(%{method: "POST", private: %{validator: validator}} = conn, _opts) do
    body_params = conn.body_params

    case validate(body_params, validator) do
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

  defp validate(body_params, %{} = types) do
    changeset = default_validator(body_params, types)

    if changeset.valid? do
      {:ok, changeset.changes}
    else
      {:error, error_messages(changeset)}
    end
  end

  defp validate(_, nil) do
    :skipped
  end

  defp validate(body_params, validator) do
    changeset = validator.(body_params)

    if changeset.valid? do
      {:ok, changeset.changes}
    else
      {:error, error_messages(changeset)}
    end
  end

  defp default_validator(body_params, types) do
    keys = Map.keys(types)

    {body_params, types}
    |> Ecto.Changeset.cast(body_params, keys)
    |> Ecto.Changeset.validate_required(keys)
  end

  defp error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
