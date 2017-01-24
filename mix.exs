defmodule Mnemonix.Mixfile do
  use Mix.Project

  def project, do: [
    name: "Mnemonix",
    app: :mnemonix,

    version: "0.7.1",
    elixir: "~> 1.3",

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
    mod: {Mnemonix, [{Mnemonix.Stores.Map, []}]},
  ]

  defp deps, do: tools() ++ backends() ++ integrations()

  defp tools, do: [
    {:dialyxir,    "~> 0.3.5", only: :dev},
    {:ex_doc,      "~> 0.14",  only: :dev},
    {:excoveralls, "~> 0.5",   only: :test},
    {:credo,       "~> 0.4",   only: [:dev, :test]},
    {:benchfella,  "~> 0.3.0", only: [:dev, :test]},
  ]

  defp backends, do: [
    {:redix,     ">= 0.0.0", only: [:dev, :test]},
    {:memcachex, ">= 0.0.0", only: [:dev, :test]},
  ]

  defp integrations, do: [
    {:plug, ">= 0.0.0", only: [:dev, :test]},
  ]

  defp docs, do: [
    main: "Mnemonix",
    # logo: "mnemonix.png",
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
      Coverage: "https://coveralls.io/github/christhekeele/mnemonix",
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
