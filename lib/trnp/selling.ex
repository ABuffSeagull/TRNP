defmodule Trnp.Selling do
  use Agent

  require Logger

  alias Nostrum.Api

  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @channel_parent_id Application.fetch_env!(:trnp, :channel_parent_id)
  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  ## Init

  defstruct channel_id: nil, user_ids: %{}

  def start_link(_initial_state),
    do: Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)

  ## Api

  def set_channel_id(id), do: Agent.cast(__MODULE__, &Map.replace!(&1, :id, id))

  def clean_channel, do: Agent.cast(__MODULE__, &remake_channel/1)

  def get_history(id) do
    Agent.get(__MODULE__, fn %__MODULE__{user_ids: user_ids} -> Map.get(user_ids, id, []) end)
  end

  ## Agent callbacks

  defp remake_channel(%__MODULE__{channel_id: nil} = state) do
    Api.create_message!(@admin_channel_id, "You forgot to set the selling channel id, dumbass")
    state
  end

  defp remake_channel(%__MODULE__{channel_id: channel_id}) do
    with {:ok, _channel} <- Api.delete_channel(channel_id, "Weekly wipe"),
         {:ok, %{channel_id: id}} <-
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
          "Something went wrong with deleting the selling channel: #{code} #{message}"
        )

        %__MODULE__{}
    end
  end
end
