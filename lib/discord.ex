defmodule Discord do
  use Nostrum.Consumer
  require Logger
  alias Nostrum.Struct.Message
  alias Nostrum.Api

  @guild_id Application.fetch_env!(:trnp, :guild_id)

  @role_message_id Application.fetch_env!(:trnp, :role_message_id)

  def start_link do
    Logger.info("Starting up")
    Consumer.start_link(__MODULE__, name: Discord)
  end

  def handle_event({:READY, _data, _ws_state}), do: Logger.info("Connected!")

  def handle_event(
        {:MESSAGE_REACTION_ADD,
         %{user_id: user_id, message_id: @role_message_id, emoji: %{name: emoji}}, _ws_state}
      ) do
    roles =
      case String.trim(emoji) do
        "🅰️" -> [Application.fetch_env!(:trnp, :role_a_id)]
        "🅱️" -> [Application.fetch_env!(:trnp, :role_b_id)]
        _ -> []
      end

    Api.modify_guild_member!(@guild_id, user_id, roles: roles)
  end

  def handle_event(event) do
    # IO.inspect(event, label: "Unhandled event")
  end
end
