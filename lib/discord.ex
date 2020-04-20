defmodule Discord do
  @moduledoc """
  Discord module for handling events and
  dispatching the correct commands
  """

  use Nostrum.Consumer

  alias Nostrum.Struct.Message

  require Logger

  @bot_id Application.fetch_env!(:trnp, :bot_id)
  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  def start_link, do: Consumer.start_link(__MODULE__, name: Discord)

  def handle_event({:READY, _data, _ws_state}), do: Logger.info("Connected!")

  # Ignore all messages from self
  def handle_event({:MESSAGE_CREATE, %Message{author: %{id: @bot_id}}, _ws_state}), do: nil

  # Handle Admin commands
  def handle_event(
        {:MESSAGE_CREATE, %Message{channel_id: @admin_channel_id, content: "!" <> command},
         _ws_state}
      ),
      do: Commands.Admin.handle_command(command)

  # Handle User commands
  def handle_event({:MESSAGE_CREATE, %Message{content: "!" <> _command} = message, _ws_state}),
    do: Commands.User.handle_command(message)

  # Handle general messages
  def handle_event({:MESSAGE_CREATE, %Message{channel_id: channel_id} = message, _ws_state}) do
    selling_channel_id = Database.get_channel_id("selling")

    case channel_id do
      ^selling_channel_id -> Trnp.Selling.handle_message(message)
      _ -> nil
    end
  end

  # Fallthrough so it doesn't error
  def handle_event(_event), do: nil
end
