import Config

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:server, :port, :reason, :message]

import_config "#{config_env()}.exs"
