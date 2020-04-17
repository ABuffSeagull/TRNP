defmodule Commands.Admin do
  alias Nostrum.Api

  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  def handle_command("set channel " <> command) do
    [channel, id] = String.split(command)

    case channel do
      "selling" ->
        id
        |> String.to_integer()
        |> Trnp.Selling.set_channel_id()

        Api.create_message!(@admin_channel_id, "Channel set")

      _ ->
        nil
    end
  end

  def handle_command(command) do
    command = String.split(command)
    Api.create_message!(@admin_channel_id, "Unknown command: #{command}")
  end
end
