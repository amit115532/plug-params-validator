import Plug.Conn
require Logger

defmodule ParamsValidation do
  @moduledoc false

  @doc """
    ## opts
    `:body_params` map mapping from an atom (param name) into an ecto type (:string, :integer, ...)
    `:path_params` map mapping from an atom (param name) into an ecto type (:string, :integer, ...)
    `:optional_body_params` a list of atoms (param names)
  """
  def expect(opts) do
    body_param_types = opts[:body_params] || %{}
    path_param_types = opts[:path_params] || %{}
    optional_body_params = opts[:optional_body_params] || []

    validate(body_param_types, path_param_types, optional_body_params)
  end

  defp validate(
         body_param_types,
         path_param_types,
         optional_body_params
       ) do
    body_keys = Map.keys(body_param_types)
    path_keys = Map.keys(path_param_types)
    required_body_params = body_keys |> Enum.filter(fn key -> key not in optional_body_params end)
    default_body_params = optional_body_params |> Map.new(fn key -> {key, nil} end)

    [
      private: %{
        params_validator:
          {body_param_types, body_keys, path_param_types, path_keys, required_body_params,
           default_body_params}
      }
    ]
  end

  def params_validation(
        %{
          method: "GET",
          private: %{
            params_validator:
              {_body_param_types, _body_keys, path_param_types, path_keys, _required_body_params,
               _default_body_params}
          }
        } = conn,
        _opts
      ) do
    path_params = conn.path_params

    case use_validator(path_params, path_param_types, path_keys, path_keys, %{}) do
      {:ok, _applied_params} ->
        conn

      :skipped ->
        conn

      {:error, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{errors: errors}))
        |> halt
    end
  end

  def params_validation(
        %{
          private: %{
            params_validator:
              {body_param_types, body_keys, path_param_types, path_keys, required_body_params,
               default_body_params}
          }
        } = conn,
        _opts
      ) do
    body_params = conn.body_params
    path_params = conn.path_params

    with {:ok, applied_body_params} <-
           use_validator(
             body_params,
             body_param_types,
             body_keys,
             required_body_params,
             default_body_params
           ),
         {:ok, _applied_path_params} <-
           use_validator(path_params, path_param_types, path_keys, path_keys, %{}) do
      %{conn | body_params: applied_body_params}
    else
      {:error, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{errors: errors}))
        |> halt
    end
  end

  def params_validation(
        conn,
        _opts
      ) do
    conn
  end

  defp use_validator(params, types, keys, required, default) do
    changeset = default_validator(params, types, keys, required)
    IO.inspect changeset
    if changeset.valid? do
      {:ok, default |> Map.merge(changeset.changes)}
    else
      {:error, error_messages(changeset)}
    end
  end

  defp default_validator(params, types, keys, required) do
    {params, types}
    |> Ecto.Changeset.cast(params, keys)
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
