defmodule Commands.User do
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  def handle_command(%Message{
        content: "!timezone" <> timezone,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    timezone = String.trim(timezone)

    message =
      if String.length(timezone) > 0 do
        case Trnp.Timezones.set_user_timezone(user_id, timezone) do
          :ok ->
            "Timezone has been set to #{timezone}"

          :error ->
            "Timezone does not exist, please consult this: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
        end
      else
        case Trnp.Timezones.get_user_timezone(user_id) do
          nil -> "You haven't set a timezone yet"
          tz -> "Your timezone is #{tz}"
        end
      end

    Api.create_message!(channel_id, "<@!#{user_id}> #{message}")
  end

  def handle_command(%Message{
        content: "!history" <> _extra,
        author: %{id: user_id},
        channel_id: channel_id
      }) do
    message =
      user_id
      |> Trnp.Selling.get_history()
      |> Enum.to_list()
      |> Enum.sort(fn {key1, _}, {key2, _} -> key1 <= key2 end)
      |> Enum.map(&format_price/1)
      |> Enum.join(", ")

    Api.create_message!(channel_id, "<@!#{user_id}> #{message}")
  end

  # Fallthrough
  def handle_command(_message), do: nil

  defp format_price({key, price}) do
    [day, time] = Regex.run(~r/(?<day>\d)_(?<time>am|pm)/, key, capture: :all_but_first)

    day =
      case day do
        "0" -> "Sunday"
        "1" -> "Monday"
        "2" -> "Tuesday"
        "3" -> "Wednesday"
        "4" -> "Thursday"
        "5" -> "Friday"
        "6" -> "Saturday"
      end

    "#{day} #{String.upcase(time)}: #{price}"
  end
end
