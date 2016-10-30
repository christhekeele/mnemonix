defmodule Mnemonix.Mixfile do
  use Mix.Project

  def project, do: [
    name: Mnemonix,
    app: :mnemonix,
    
    version: "0.1.0",
    elixir: "~> 1.2",
    
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    
    deps: deps(),
    docs: docs(),
    package: package(),
    
    source_url:   package()[:links][:Source],
    homepage_url: package()[:links][:Homepage],
    
    test_coverage: coverage()
  ]
  
  def application, do: [
    applications: [:logger],
  ]
  
  defp deps, do: [
    {:ex_doc,      "~> 0.14", only: :dev},
    {:excoveralls, "~> 0.5",  only: :test}
  ]
  
  defp docs, do: [
    main: Mnemonix,
    # logo: "",
    extras: [
      "README.md",
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
      Source: "https://github.com/christhekeele/mnemonix",
      Homepage: "https://christhekeele.github.io/mnemonix",
      Tests: "https://travis-ci.org/christhekeele/mnemonix",
    }
  ]
  
  defp coverage, do: [
    tool: ExCoveralls, 
    coveralls: true,
  ]
  
end
