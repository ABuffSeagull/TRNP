defmodule Commands.User do
  alias Nostrum.Api
  alias Nostrum.Struct.Message
  alias Timex.Timezone

  @empty_list Enum.map(0..11, fn _ -> nil end)

  @spec handle_command(%Message{}) :: :ok
  def handle_command(%Message{
        content: "!timezone" <> timezone,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    timezone = String.trim(timezone)

    message =
      if String.length(timezone) > 0 do
        if Timezone.exists?(timezone) do
          Database.set_user_timezone(user_id, timezone)
          "Timezone has been set to #{timezone}"
        else
          "Timezone does not exist, please consult this: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
        end
      else
        case Database.get_user_timezone(user_id) do
          nil -> "You haven't set a timezone yet"
          tz -> "Your timezone is #{tz}"
        end
      end

    Api.create_message!(channel_id, content: "<@!#{user_id}> #{message}")
    :ok
  end

  def handle_command(%Message{
        content: "!history" <> _extra,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    prices = Database.get_history(user_id)
    [%{base_price: base_price} | _] = prices

    price_string =
      prices
      |> Enum.filter(&is_number(&1.price))
      |> Enum.reduce(@empty_list, &List.update_at(&2, &1.time_index, fn _ -> &1.price end))
      |> Enum.map(&(&1 || "\\_"))
      |> Enum.join(", ")

    Api.create_message!(channel_id,
      content:
        "<@!#{user_id}> Buying Price: #{base_price || 'unknown'}, Price History: #{price_string}"
    )

    :ok
  end

  def handle_command(%Message{
        content: "!buying" <> price,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    price = String.trim(price)

    message =
      case Integer.parse(price) do
        :error ->
          "Unable to parse #{price}"

        {num, _} ->
          Database.set_buying_price(user_id, num)
          "Set buying price to #{num}"
      end

    Api.create_message(channel_id, content: "<@!#{user_id}> #{message}")
    :ok
  end

  # Fallthrough
  def handle_command(_message), do: :ok
end
