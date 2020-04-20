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

  def add_price(%{user_id: user_id, price: price, day: day, is_afternoon: is_afternoon}) do
    Agent.cast(__MODULE__, fn db ->
      query!(db, "INSERT INTO prices
                  (price, day, is_afternoon, user_id) VALUES (?1, ?2, ?3, ?4)
                  ON CONFLICT(day, is_afternoon, user_id) DO UPDATE SET price = ?1",
        bind: [price, day, is_afternoon, user_id]
      )

      db
    end)
  end

  def get_history(user_id) do
    Agent.get(__MODULE__, fn db ->
      query!(
        db,
        "SELECT
          price,
          day * 2 + is_afternoon as time_index
        FROM prices
        WHERE user_id = ? ORDER BY time_index DESC",
        bind: [user_id],
        into: %{}
      )
    end)
  end

  def reset_prices do
    Agent.cast(__MODULE__, fn db ->
      query!(db, "DELETE FROM prices")
      db
    end)
  end
end
