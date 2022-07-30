defmodule IdleBot.Config do
  @moduledoc false

  def get_env_cfg(var, default \\ nil) do
    System.get_env(var, default) || raise "Missing environment variable #{var}"
  end
end
