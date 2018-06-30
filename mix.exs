defmodule QfitParametersValidation.MixProject do
  use Mix.Project

  def project do
    [
      app: :qfit_parameters_validation,
      version: "0.1.2",
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
      organization: "qfit",
      description: "provides functionality for validating HTTP request parameters",
      licenses: ["MIT License"],
      # These are the default files included in the package
      files: ["lib", "mix.exs", "LICENSE.md", "README.md"],
      maintainers: ["Amit Ozalvo", "Guy Lyuboshits"],
      links: %{"GitLab" => "https://gitlab.com/qfit/qfit-parameters_validation"}
    ]
  end
end
