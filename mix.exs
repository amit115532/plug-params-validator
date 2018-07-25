defmodule ParamsValidation.MixProject do
  use Mix.Project

  def project do
    [
      app: :plug_params_validation,
      version: "0.1.7",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:ecto, "~> 2.2"},
      {:credo, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      description: "a plug for params validation",
      licenses: ["MIT License"],
      # These are the default files included in the package
      files: ["lib", "mix.exs", "LICENSE.md", "README.md"],
      maintainers: ["Amit Ozalvo"],
      links: %{"GitLab" => "https://github.com/amit115532/plug-params-validator"}
    ]
  end
end
