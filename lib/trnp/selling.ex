defmodule Trnp.Selling do
  require Logger

  alias Nostrum.Api
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.Channel

  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @channel_parent_id Application.fetch_env!(:trnp, :channel_parent_id)

  @spec clean_channel() :: :ok
  def clean_channel do
    channel_id = Database.get_channel_id("selling")
    Api.delete_channel!(channel_id, "Weekly wipe")

    %Channel{id: channel_id} =
      Api.create_guild_channel!(@guild_id,
        name: "selling-prices",
        parent_id: @channel_parent_id
      )

    Database.set_channel_id("selling", channel_id)
    :ok
  end

  @spec handle_message(%Message{}) :: :ok | nil
  def handle_message(%Message{
        content: content,
        author: %{id: user_id},
        timestamp: timestamp,
        id: message_id
      }) do
    case Regex.run(~r/price: (\d+)/i, content) do
      nil ->
        nil

      [_full, bells] ->
        add_price(%{
          price: String.to_integer(bells),
          user_id: user_id,
          timestamp: timestamp,
          message_id: message_id
        })
    end
  end

  @spec add_price(%{
          user_id: pos_integer(),
          price: pos_integer(),
          timestamp: String.t(),
          message_id: pos_integer
        }) :: :ok
  defp add_price(%{
         user_id: user_id,
         price: price,
         timestamp: timestamp,
         message_id: message_id
       }) do
    channel_id = Database.get_channel_id("selling")

    case Database.get_user_timezone(user_id) do
      nil ->
        Api.create_message(
          channel_id,
          content: "<@!#{user_id}> You haven't set your timezone yet. Use $timezone <timezone>"
        )

      timezone ->
        {:ok, datetime, 0} = DateTime.from_iso8601(timestamp)
        {:ok, datetime} = DateTime.shift_zone(datetime, timezone)

        Database.add_price(%{
          user_id: user_id,
          price: price,
          time_index:
            (Date.day_of_week(datetime) - 1) * 2 + if(datetime.hour >= 12, do: 1, else: 0)
        })

        Api.create_reaction!(channel_id, message_id, "✅")
    end

    :ok
  end
end
