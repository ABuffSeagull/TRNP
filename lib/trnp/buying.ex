defmodule Trnp.Buying do
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  # TODO: combine with the same function in Selling
  @spec handle_message(%Message{}) :: :ok | nil
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
          price: String.to_integer(bells),
          user_id: user_id,
          message_id: message_id
        })
    end
  end

  @spec add_price(%{price: pos_integer(), user_id: pos_integer(), message_id: pos_integer}) :: :ok
  defp add_price(%{price: price, user_id: user_id, message_id: message_id}) do
    channel_id = Database.get_channel_id("buying")

    Database.set_buying_price(user_id, price)

    Api.create_reaction!(channel_id, message_id, "✅")

    :ok
  end
end
