defmodule Discord do
  @moduledoc """
  Discord module for handling events and
  dispatching the correct commands
  """

  use Nostrum.Consumer

  alias Nostrum.Struct.Message
  alias Nostrum.Struct.Guild
  alias Nostrum.Api
  alias Nostrum.Cache

  require Logger

  @guild_id Application.fetch_env!(:trnp, :guild_id)

  @role_message_id Application.fetch_env!(:trnp, :role_message_id)

  def start_link do
    Consumer.start_link(__MODULE__, name: Discord)
  end

  def handle_event({:READY, _data, _ws_state}), do: Logger.info("Connected!")

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %{user_id: user_id, message_id: @role_message_id, emoji: %{name: emoji}}, _ws_state}
      ) do
    %Guild{members: %{^user_id => %{roles: roles}}} = Cache.GuildCache.get!(@guild_id)

    role_a = Application.fetch_env!(:trnp, :role_a_id)
    role_b = Application.fetch_env!(:trnp, :role_b_id)

    roles = [
      case String.trim(emoji) do
        "🅰️" -> role_a
        "🅱️" -> role_b
      end
      | roles
        |> Enum.filter(&(&1 not in [role_a, role_b]))
    ]

    Api.modify_guild_member!(@guild_id, user_id, roles: roles)
  end

  def handle_event(event) do
    # IO.inspect(event, label: "Unhandled event")
  end
end
