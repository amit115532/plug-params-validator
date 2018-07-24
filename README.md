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
In your router:
```elixir
import ParamsValidation
```

in order to get easy access to `expect/1` function and `:params_validation` plug

Then, add the following plug. make sure it happens after the body parser plug:
```elixir
plug :params_validation
```

Now, every endpoint with `expect/1` will validate what ever you specify in `expect`
example:
```elixir
post "/register", expect(body_params: %{first_name: :string, last_name: :string, age: :integer}) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num

  ...
end
```

if you would like to specify optional fields, you can pass a list to the `:optional_body_params` parameter in `expect/2`
optionals will be defaulted to nil.
example:
```elixir
post "/register", validate(body_params: %{first_name: :string, last_name: :string, age: :integer, phone: :string}, 
    optional_body_params: [:phone]) do
  first_name = conn.body_params.first_name
  last_name = conn.body_params.last_name
  age = conn.body_params.num

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

You can mix between `body_params` `optional_body_params` and `path_params` inside `POST`, `PUT`...

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