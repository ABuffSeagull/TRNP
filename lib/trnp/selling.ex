defmodule Trnp.Selling do
  use Timex

  require Logger

  alias Nostrum.Api
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.Channel

  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @channel_parent_id Application.fetch_env!(:trnp, :channel_parent_id)

  def clean_channel do
    channel_id = Database.get_channel_id("selling")
    Api.delete_channel!(channel_id, "Weekly wipe")

    %Channel{id: channel_id} =
      Api.create_guild_channel!(@guild_id,
        name: "selling-prices",
        parent_id: @channel_parent_id
      )

    Database.set_channel_id("selling", channel_id)
  end

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
          price: bells,
          user_id: user_id,
          timestamp: timestamp,
          message_id: message_id
        })
    end
  end

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
          content: "<@!#{user_id}> You haven't set your timezone yet. Use !timezone <timezone>"
        )

      timezone ->
        datetime =
          timestamp
          |> Timex.parse!("{ISO:Extended}")
          |> Timezone.convert(timezone)

        Database.add_price(%{
          user_id: user_id,
          price: price,
          day: Timex.weekday(datetime) - 1,
          is_afternoon: datetime.hour >= 12
        })

        Api.create_reaction!(channel_id, message_id, "✅")
    end
  end
end
