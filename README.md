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
import BodyParamsValidation
```

in order to get easy access to `validate/1` function and `:body_param_validation` plug

Then, add the following plug. make sure it happens after the body parser plug:
```elixir
plug :parameters_validation
```

Now, every post endpoint with `validate/1` will validate `body_params`
example:
```elixir
post "/register", validate(%{first_name: :string, last_name: :string, age: :integer}) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num

  ...
end
```

if you would like to specify optional fields, you can pass a list to the `:optionals` parameter in `validate/2`
optionals will be defaulted to nil.
example:
```elixir
post "/register", validate(%{first_name: :string, last_name: :string, age: :integer, phone: :string}, optionals: [:phone]) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num

  phone = conn.body_params.phone || Phone.default_value 
  ...
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