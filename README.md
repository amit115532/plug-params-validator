# QfitParametersValidation

Provides functionality for validating http request parameters

## Installation

```elixir
def deps do
  [
    {:qfit_parameters_validation, "~> 0.1.0"}
  ]
end
```

## Usage
In your router:
```elixir
import Qfit.Plug.ParametersValidator
```

in order to get easy access to validate/1 function and :parameters_validation plug

Then, add the following plug. make sure it happens after the body parser plug:
```elixir
plug :parameters_validation
```

Now, every post endpoint with validate/1 will validate body_params
example:
```elixir
post "/register", validate(%{first_name: :string, last_name: :string, age: :integer}) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num

  ...
end
```

validate is also taking a delegate to a validation function which should return an
ecto changeset. This allows for a more complex validation.
lets say, age can only be larger than 12:

```elixir
post "/register", validate(&register_validation/2) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num
  ...
end

defp register_validation(body_params) do
  types = %{first_name: :string, last_name: :string, age: :integer}
  keys = Map.keys(%{first_name: :string, last_name: :string, age: :integer})
  {body_params, types}
    |> Ecto.Changeset.cast(body_params, keys)
    |> Ecto.Changeset.validate_required(keys)
    |> Ecto.Changeset.validate_number(:age, greater_than: 12)
end
```

When a request with bad parameters happens, the plug response with
status code 400 and the following body:

```json
{
    "errors": {
        "last_name": [
            "can't be blank"
        ],
        "age": [
            "can't be blank"
        ]
    }
}
```