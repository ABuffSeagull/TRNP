defmodule Commands.User do
  alias Nostrum.Api

  def handle_command(%{
        command: "timezone" <> timezone,
        user_id: user_id,
        channel_id: channel_id
      }) do
    timezone = String.trim(timezone)

    message =
      if String.length(timezone) > 0 do
        case Trnp.Timezones.set_user_timezone(user_id, timezone) do
          :ok -> "Timezone has been set to #{timezone}"
          :error -> "Timezone does not exist"
        end
      else
        case Trnp.Timezones.get_user_timezone(user_id) do
          nil -> "You haven't set a timezone yet"
          tz -> "Your timezone is #{tz}"
        end
      end

    Api.create_message!(channel_id, content: "<@!#{user_id}> #{message}")
  end

  # Fallthrough
  def handle_command(_message), do: nil
end
