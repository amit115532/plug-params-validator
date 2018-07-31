# PlugParamsValidation

Provides functionality for validating parameters

## Installation

```elixir
def deps do
  [
    {:plug_params_validation, "~> 0.1.0"}
  ]
end
```

## Usage
```elixir
import ParamsValidation, only: [expect: 1]
```
In order to get easy access to `expect/1` function.

Next, add the following plug after `plug :match` 
```elixir
plug(ParamsValidation, log_errors?: true)
```

Now, every endpoint with `expect/1` will validate what ever you specify in `expect`
## Example
```elixir
post "/register", expect(body_params: %{first_name: :string, last_name: :string, age: :integer}) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.age

  ...
end
```

if you would like to specify optional fields, you can pass a list to the `:optional_body_params` parameter in `expect/1`
optionals will be defaulted to nil.
example:
```elixir
post "/register", expect(body_params: %{first_name: :string, last_name: :string, age: :integer, phone: :string}, 
    optional_body_params: [:phone]) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.age

  phone = conn.body_params.phone || Phone.default_value 
  ...
end
```

this also works for `GET` requests: 
example:
```elixir
get "/register/:name", expect(path_params: %{name: :string}) do
  # name can be used and trusted to be a string
  ...
end
```

You can mix between `body_params` `optional_body_params` `path_params` and `query_params`...

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