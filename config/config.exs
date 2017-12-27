use Mix.Config

configs = ["#{Mix.env}.exs"]

for config <- configs do
  if File.exists?("config/#{config}"), do: import_config(config)
end
