defmodule Discord do
  @moduledoc """
  Discord module for handling events and
  dispatching the correct commands
  """

  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Message

  require Logger

  @bot_id Application.fetch_env!(:trnp, :bot_id)
  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @role_message_id Application.fetch_env!(:trnp, :role_message_id)
  @selling_channel_id Application.fetch_env!(:trnp, :selling_channel_id)

  def start_link do
    Consumer.start_link(__MODULE__, name: Discord)
  end

  def handle_event({:READY, _data, _ws_state}), do: Logger.info("Connected!")

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %{user_id: user_id, message_id: @role_message_id, emoji: %{name: emoji}}, _ws_state}
      ) do
    %Guild{members: %{^user_id => %Member{roles: roles}}} = Cache.GuildCache.get!(@guild_id)

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

  # Ignore all messages from self
  def handle_event({:MESSAGE_CREATE, %Message{author: %{id: @bot_id}}, _ws_state}), do: nil

  # when author_id != 696_117_361_044_095_126 do
  def handle_event(
        {:MESSAGE_CREATE,
         %Message{
           channel_id: @selling_channel_id
         } = message, _ws_state}
      ) do
    Trnp.Buying.update(message)
  end

  def handle_event(_event) do
    # IO.inspect(event, label: "Unhandled event")
  end
end
