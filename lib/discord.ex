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

  def handle_event(
        {:MESSAGE_CREATE,
         %Message{content: "!" <> command, author: %{id: user_id}, channel_id: channel_id},
         _ws_state}
      ),
      do:
        Commands.User.handle_command(%{command: command, user_id: user_id, channel_id: channel_id})

  # Fallthrough so it doesn't error
  def handle_event(_event), do: nil
end
