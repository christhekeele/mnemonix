defmodule Mnemonix.Mixfile do
  use Mix.Project

  def project, do: [
    app: :mnemonix,
    name: "Mnemonix",
    version: "0.10.0",

    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,

    deps: deps(),
    elixir: "~> 1.5",

    docs: docs(),
    package: package(),

    source_url:   package()[:links][:Source],
    homepage_url: package()[:links][:Homepage],

    aliases: aliases(),
    dialyzer: dialyzer(),
    test_coverage: coverage(),
  ]

  def application, do: [
    extra_applications: [:logger],
    mod: {Mnemonix.Application, [{Mnemonix.Stores.Map, []}]},
  ]

  defp deps, do: tools() ++ backends() ++ integrations()

  defp tools, do: [
    {:benchfella,  "~> 0.3",  only: [:dev, :test]},
    {:credo,       "~> 0.6",  only: [:dev, :test]},
    {:dialyxir,    "~> 0.5",  only: [:dev, :test]},
    {:excoveralls, "~> 0.6",  only: [:dev, :test]},
    {:ex_doc,      "~> 0.15", only: [:dev, :test]},
    {:inch_ex,     "~> 0.5",  only: [:dev, :test]},
  ]

  defp backends, do: [
    {:elastix,   ">= 0.4.0", only: [:dev, :test]},
    {:memcachex, ">= 0.0.0", only: [:dev, :test]},
    {:redix,     ">= 0.0.0", only: [:dev, :test]},
  ]

  defp integrations, do: [
    {:plug, ">= 0.0.0", only: [:dev, :test]},
  ]

  defp docs, do: [
    main: "Mnemonix",
    extras: [
      "CREDITS.md",
      "LICENSE.md",
    ],
    groups_for_modules: [
      # Features: ~r<Mnemonix.Features>,
      Integrations: [Plug.Session.MNEMONIX],
      # Supervision: [Mnemonix.Application, Mnemonix.Supervisor],
      Stores: ~r<Mnemonix.Stores>,
    ]
  ]

  defp package, do: [
    description: "A unified interface to key/value stores.",
    maintainers: [
      "Chris Keele <christhekeele+mnemonix@gmail.com>",
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

  defp aliases, do: [
    default: ~w[test dialyzer coveralls.html docs],
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
