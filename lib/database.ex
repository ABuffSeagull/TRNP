defmodule Database do
  use Agent

  import Sqlitex

  def start_link(filename) do
    {:ok, db} = open(filename)
    Agent.start_link(fn -> db end, name: __MODULE__)
  end

  def get_channel_id(channel) do
    Agent.get(__MODULE__, fn db ->
      query!(db, "SELECT channel_id FROM channels WHERE name = ?", bind: [channel])
      |> List.first()
      |> Keyword.fetch!(:channel_id)
    end)
  end

  def set_channel_id(channel, id) do
    Agent.cast(__MODULE__, fn db ->
      query!(db, "UPDATE channels SET channel_id = ? WHERE name = ?", bind: [id, channel])
      db
    end)
  end

  def set_user_timezone(id, timezone) do
    Agent.cast(__MODULE__, fn db ->
      query!(db, "INSERT INTO users
                  (id, timezone) VALUES (?1, ?2)
                  ON CONFLICT(id) DO UPDATE SET timezone = ?2", bind: [id, timezone])
      db
    end)
  end

  def get_user_timezone(id) do
    Agent.get(__MODULE__, fn db ->
      query!(db, "SELECT timezone FROM users WHERE id = ?", bind: [id])
      |> Enum.at(0, [])
      |> Keyword.get(:timezone, nil)
    end)
  end
end
