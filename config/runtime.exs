import Config
import IdleBot.Config


config :idlebot,
  host: get_env_cfg("IDLEBOT_IRC_HOST"),
  port: get_env_cfg("IDLEBOT_IRC_PORT", "6667") |> String.to_integer(),
  password: get_env_cfg("IDLEBOT_IRC_PASSWORD", ""),
  nick: get_env_cfg("IDLEBOT_IRC_NICK", "idlebot"),
  user: get_env_cfg("IDLEBOT_IRC_USER", "idlebot"),
  name: get_env_cfg("IDLEBOT_IRC_NAME", "Idle Bot"),
  tls: get_env_cfg("IDLEBOT_IRC_TLS", "no") == "yes"
