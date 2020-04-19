defmodule Commands.Admin do
  alias Nostrum.Api

  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  def handle_command("set channel " <> command) do
    [channel, id] = String.split(command)

    Database.set_channel_id(channel, id)

    Api.create_message!(@admin_channel_id, content: "Channel set")
  end

  def handle_command(command) do
    command = String.split(command)
    Api.create_message!(@admin_channel_id, content: "Unknown command: #{command}")
  end
end
