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
    test_coverage: coverage(),
    dialyzer_warnings: warnings(),
    dialyzer_ignored_warnings: ignore_warnings(),
  ]

  def application, do: [
    extra_applications: [:logger],
    mod: {Mnemonix.Application, [{Mnemonix.Stores.Map, []}]},
  ]

  defp deps, do: tools() ++ backends() ++ integrations()

  defp tools, do: [
    {:benchfella,  "~> 0.3",  only: [:dev, :test]},
    {:cortex,      "~> 0.4",  only: [:dev, :test]},
    {:credo,       "~> 0.6",  only: [:dev, :test]},
    {:dialyzex,    "~> 1.0",  only: [:dev, :test]},
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
      "README.md",
      "LICENSE.md",
      "CREDITS.md",
      "CONTRIBUTING.md",
      "CODE_OF_CONDUCT.md",
    ],
    groups_for_modules: [
      Functions: [Mnemonix.Builder, Mnemonix.Supervision, ~r<Mnemonix.Features.>],
      Integrations: [Plug.Session.MNEMONIX],
      Stores: ~r<Mnemonix.Stores.(?!Meta)>,
      MetaStores: ~r<Mnemonix.Stores.Meta>,
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
    checks: ~w[bench coveralls.html dialyzer docs inch],
  ]

  defp coverage, do: [
    tool: ExCoveralls,
    coveralls: true,
  ]

  defp warnings, do: [
    :unmatched_returns,
    :error_handling,
    :race_conditions,
    # :underspecs, # Explicitly removed
    :unknown,
  ]

  defp ignore_warnings, do: [
    # We intentionally overlap specs here to serve as documentation for
    # each handle_call case.
    {:warn_contract_types,
      {'lib/mnemonix/store/server.ex', :_},
      {:overlapping_contract, [Mnemonix.Store.Server, :handle_call, 3]}
    },
    # Errant warnings currently generated by a `defprotocol`
    # in any dependency
    {:warn_matching,
      {:_, :_},
      {:guard_fail, [:or, '(\'false\',\'false\')']}
    },
    {:warn_not_called,
      {:_, :_},
      {:unused_fun, [:any_impl_for, 0]}
    },
    {:warn_not_called,
      {:_, :_},
      {:unused_fun, [:impl_for?, 1]}
    },
  ]

end
