defmodule Trnp.Selling do
  use Timex
  use Agent

  require Logger

  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @channel_parent_id Application.fetch_env!(:trnp, :channel_parent_id)
  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  @empty_list Enum.map(0..11, fn _ -> nil end)

  ## Init

  defstruct channel_id: nil, user_ids: %{}

  def start_link(_initial_state),
    do: Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)

  ## Api

  def set_channel_id(id), do: Agent.cast(__MODULE__, &%{&1 | channel_id: id})

  def get_channel_id, do: Agent.get(__MODULE__, & &1.channel_id)

  def clean_channel, do: Agent.cast(__MODULE__, &remake_channel/1)

  def get_history(id) do
    Agent.get(__MODULE__, fn %__MODULE__{user_ids: user_ids} ->
      Map.get(user_ids, id, @empty_list)
    end)
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
        Agent.cast(
          __MODULE__,
          &add_price(&1, %{
            price: bells,
            user_id: user_id,
            timestamp: timestamp,
            message_id: message_id
          })
        )
    end
  end

  ## Agent callbacks

  defp remake_channel(%__MODULE__{channel_id: nil} = state) do
    Api.create_message!(@admin_channel_id,
      content: "You forgot to set the selling channel id, dumbass"
    )

    state
  end

  defp remake_channel(%__MODULE__{channel_id: channel_id}) do
    with {:ok, _channel} <- Api.delete_channel(channel_id, "Weekly wipe"),
         {:ok, %{id: id}} <-
           Api.create_guild_channel(@guild_id,
             name: "selling-prices",
             parent_id: @channel_parent_id
           ) do
      %__MODULE__{channel_id: id}
    else
      {:error, error} ->
        %{response: %{message: message}, status_code: code} = error

        Api.create_message!(
          @admin_channel_id,
          content: "Something went wrong with deleting the selling channel: #{code} #{message}"
        )

        %__MODULE__{}
    end
  end

  defp add_price(%__MODULE__{channel_id: channel_id, user_ids: user_ids} = state, %{
         user_id: user_id,
         price: price,
         timestamp: timestamp,
         message_id: message_id
       }) do
    case Database.get_user_timezone(user_id) do
      nil ->
        Api.create_message(
          channel_id,
          content: "<@!#{user_id}> You haven't set your timezone yet. Use !timezone <timezone>"
        )

        state

      timezone ->
        datetime =
          timestamp
          |> Timex.parse!("{ISO:Extended}")
          |> Timezone.convert(timezone)

        index = Timex.weekday(datetime) - 2 + if(datetime.hour < 12, do: 1, else: 0)

        prices =
          user_ids
          |> Map.get(user_id, @empty_list)
          |> List.insert_at(index, price)

        user_ids = Map.put(user_ids, user_id, prices)

        Api.create_reaction!(channel_id, message_id, "✅")

        %__MODULE__{state | user_ids: user_ids}
    end
  end
end
