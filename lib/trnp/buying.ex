defmodule Trnp.Buying do
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  # TODO: combine with the same function in Selling
  def handle_message(%Message{
        content: content,
        author: %{id: user_id},
        id: message_id
      }) do
    case Regex.run(~r/price: (\d+)/i, content) do
      nil ->
        nil

      [_full, bells] ->
        add_price(%{
          price: bells,
          user_id: user_id,
          message_id: message_id
        })
    end
  end

  defp add_price(%{price: price, user_id: user_id, message_id: message_id}) do
    channel_id = Database.get_channel_id("buying")

    Database.set_buying_price(user_id, price)

    Api.create_reaction!(channel_id, message_id, "✅")
  end
end
