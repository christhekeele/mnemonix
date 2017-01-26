exclusions = []

exclusions = if System.get_env("DOCTESTS"), do: exclusions, else: [:doctest | exclusions]

ExUnit.start(exclude: exclusions)
