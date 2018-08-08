require Logger
import Plug.Conn
require Logger

defmodule ParamsValidation do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      require ParamsValidation
      import ParamsValidation, only: [expect: 1, body_params: 0, query_params: 0]
    end
  end

  @spec body_params :: any
  defmacro body_params do
    quote do
      var!(conn).private.params_validator_result.body_params
    end
  end

  @spec query_params :: any
  defmacro query_params do
    quote do
      var!(conn).private.params_validator_result.query_params
    end
  end

  @doc """
  # opts
  :log_errors? - boolean value indicating whether to log errors (defaults to false)
  """
  def init(opts) do
    [log_errors?: opts[:log_errors?] || false]
  end

  @doc """
    ## opts
    `:body_params` map mapping from an atom (param name) into an ecto type (:string, :integer, ...)
    `:path_params` map mapping from an atom (param name) into an ecto type (:string, :integer, ...)
    `:optional_body_params` a list of atoms (param names)
  """
  def expect(opts) do
    body_param_types = opts[:body_params] || %{}
    path_param_types = opts[:path_params] || %{}
    query_param_types = opts[:query_params] || %{}
    optional_body_params = opts[:optional_body_params] || []

    validate(body_param_types, path_param_types, query_param_types, optional_body_params)
  end

  defp validate(
         body_param_types,
         path_param_types,
         query_param_types,
         optional_body_params
       ) do
    body_keys = Map.keys(body_param_types)
    path_keys = Map.keys(path_param_types)
    query_keys = Map.keys(query_param_types)
    required_body_params = body_keys |> Enum.filter(fn key -> key not in optional_body_params end)
    default_body_params = optional_body_params |> Map.new(fn key -> {key, nil} end)
    default_query_params = query_keys |> Map.new(fn key -> {key, nil} end)

    [
      private: %{
        params_validator:
          {body_param_types, body_keys, path_param_types, path_keys, required_body_params,
           default_body_params, query_param_types, query_keys, default_query_params}
      }
    ]
  end

  def call(
        %{
          method: "GET",
          private: %{
            params_validator:
              {_body_param_types, _body_keys, path_param_types, path_keys, _required_body_params,
               _default_body_params, query_param_types, query_keys, default_query_params}
          }
        } = conn,
        log_errors?: log_errors?
      ) do
    path_params = conn.path_params
    query_params = conn.query_params

    with {:ok, _applied_params} <-
           use_validator(path_params, path_param_types, path_keys, path_keys, %{}),
         {:ok, applied_query_params} <-
           use_validator(query_params, query_param_types, query_keys, [], default_query_params) do
      params_validator_result = %{query_params: applied_query_params}
      conn |> Plug.Conn.put_private(:params_validator_result, params_validator_result)
    else
      {:error, errors} ->
        if log_errors?, do: log_error(errors)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{errors: errors}))
        |> halt
    end
  end

  def call(
        %{
          private: %{
            params_validator:
              {body_param_types, body_keys, path_param_types, path_keys, required_body_params,
               default_body_params, query_param_types, query_keys, default_query_params}
          }
        } = conn,
        log_errors?: log_errors?
      ) do
    body_params = conn.body_params
    path_params = conn.path_params
    query_params = conn.query_params

    with {:ok, applied_body_params} <-
           use_validator(
             body_params,
             body_param_types,
             body_keys,
             required_body_params,
             default_body_params
           ),
         {:ok, _applied_path_params} <-
           use_validator(path_params, path_param_types, path_keys, path_keys, %{}),
         {:ok, applied_query_params} <-
           use_validator(query_params, query_param_types, query_keys, [], default_query_params) do

      params_validator_result = %{body_params: applied_body_params, query_params: applied_query_params}
      conn |> Plug.Conn.put_private(:params_validator_result, params_validator_result)
    else
      {:error, errors} ->
        if log_errors?, do: log_error(errors)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{errors: errors}))
        |> halt
    end
  end

  def call(
        conn,
        _opts
      ) do
    conn
  end

  @spec use_validator(map, map, list, list, map) :: {:ok, map} | {:error, any}
  defp use_validator(%Plug.Conn.Unfetched{}, _, _, _, _) do
    {:ok, %{}}
  end

  defp use_validator(params, types, keys, required, default) do
    changeset = default_validator(params, types, keys, required)

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

  defp log_error(error) do
    Logger.error("params_validation error: #{inspect(error)}")
  end
end
