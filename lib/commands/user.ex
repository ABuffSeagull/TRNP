defmodule Commands.User do
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  require Logger

  @empty_list Enum.map(0..11, fn _ -> nil end)
  @pattern_names %{
    large_spike: "Large Spike",
    small_spike: "Small Spike",
    decreasing: "Decreasing",
    random: "Fluctuating"
  }

  @spec handle_command(%Message{}) :: :ok
  def handle_command(%Message{
        content: "$timezone" <> timezone,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    Logger.debug("Handling command timezone for #{user_id} in #{channel_id}")
    timezone = String.trim(timezone)

    message =
      if String.length(timezone) > 0 do
        if Tzdata.zone_exists?(timezone) do
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
        content: "$history" <> _extra,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    Logger.debug("Handling command history for #{user_id} in #{channel_id}")
    prices = Database.get_price_info(user_id)
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
        content: "$buying" <> price,
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

  def handle_command(%Message{
        content: "$pattern" <> _extra,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    prices = Database.get_price_info(user_id)
    [%{base_price: base_price, last_pattern: last_pattern} | _] = prices

    pattern_chances =
      prices
      |> Enum.filter(&is_number(&1.price))
      |> Enum.reduce(@empty_list, &List.update_at(&2, &1.time_index, fn _ -> &1.price end))
      |> Trnp.Patterns.match(base_price, last_pattern)
      |> Enum.group_by(fn {type, _, _} -> type end, fn {_, _, weight} -> weight end)
      |> Enum.map(fn {type, weights} -> {type, Enum.sum(weights)} end)
      |> Enum.filter(fn {_type, weight} -> weight > 0.001 end)
      |> Enum.map(fn {type, weight} -> {@pattern_names[type], round(weight * 100)} end)
      |> Enum.sort_by(fn {_type, weight} -> weight end)
      |> Enum.reverse()
      |> Enum.map(fn {type, weight} -> "#{type}: #{weight}%" end)
      |> Enum.join(", ")

    Api.create_message(channel_id, content: "<@!#{user_id}> #{pattern_chances}")
  end

  # Fallthrough
  def handle_command(_message), do: :ok
end
