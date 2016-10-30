defmodule Mnemonix.Mixfile do
  use Mix.Project

  def project, do: [
    name: "Mnemonix",
    app: :mnemonix,
    
    version: "0.1.1",
    elixir: "~> 1.2",
    
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    
    deps: deps(),
    docs: docs(),
    package: package(),
    
    source_url:   package()[:links][:Source],
    homepage_url: package()[:links][:Homepage],
    
    test_coverage: coverage(),
    dialyzer: dialyzer(),
  ]
  
  def application, do: [
    applications: [:logger],
  ]
  
  defp deps, do: [
    {:dialyxir,    "~> 0.3.5", only: :dev},
    {:ex_doc,      "~> 0.14",  only: :dev},
    {:excoveralls, "~> 0.5",   only: :test},
  ]
  
  defp docs, do: [
    main: "Mnemonix",
    # logo: "",
    extras: [
      "README.md",
      "CREDITS.md",
      "LICENSE.md",
    ]
  ]
  
  defp package, do: [
    description: "A unified interface to key-value stores.",
    maintainers: [
      "Chris Keele <dev@chriskeele.com>",
    ],
    licenses: [
      "MIT",
    ],
    links: %{
      Homepage: "https://christhekeele.github.io/mnemonix",
      Source: "https://github.com/christhekeele/mnemonix",
      Tests: "https://travis-ci.org/christhekeele/mnemonix",
      Coverage: "https://travis-ci.org/christhekeele/mnemonix",
    }
  ]
  
  defp coverage, do: [
    tool: ExCoveralls, 
    coveralls: true,
  ]
  
  defp dialyzer, do: [
    plt_add_apps: [
      :mnesia, 
      # :ecto,
    ]
  ]
  
end
