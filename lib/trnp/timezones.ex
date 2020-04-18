defmodule Trnp.Timezones do
  use Agent

  alias Timex.Timezone

  @file_path Application.fetch_env!(:trnp, :tz_file_path)
  @file_name Application.fetch_env!(:trnp, :tz_file_name)

  defp file, do: Path.join(@file_path, @file_name)

  def start_link(_) do
    tz_map =
      file()
      |> File.read!()
      |> Jason.decode!(strings: :copy)
      |> Enum.map(fn {id, timezone} -> {String.to_integer(id), timezone} end)
      |> Map.new()

    Agent.start_link(fn -> tz_map end, name: __MODULE__)
  end

  def get_user_timezone(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end

  def set_user_timezone(user_id, timezone) do
    if Timezone.exists?(timezone) do
      Agent.cast(__MODULE__, &set_user_timezone(&1, user_id, timezone))
      :ok
    else
      :error
    end
  end

  defp set_user_timezone(ts_map, user_id, timezone) do
    ts_map = Map.put(ts_map, user_id, timezone)

    json = Jason.encode!(ts_map)
    File.write!(file(), json)

    ts_map
  end
end
