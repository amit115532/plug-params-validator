defmodule ParamsValidation.Regex do
  defmacro __using__(opts) do
    regex = opts |> Keyword.fetch!(:regex)

    quote do
      @behaviour Ecto.Type
      def type, do: :string

      def cast(value) when is_bitstring(value) or is_number(value) do
        if Regex.match?(unquote(regex), value),
          do: {:ok, value},
          else: :error
      end

      def cast(_), do: :error
      def load(_), do: :error
      def dump(_), do: :error
    end
  end
end
