defmodule Trnp.Selling do
  use Agent

  require Logger

  alias Nostrum.Api

  @guild_id Application.fetch_env!(:trnp, :guild_id)
  @channel_parent_id Application.fetch_env!(:trnp, :channel_parent_id)
  @admin_channel_id Application.fetch_env!(:trnp, :admin_channel_id)

  def start_link(_initial_state),
    do: Agent.start_link(fn -> %{id: nil, prices: []} end, name: __MODULE__)

  def set_channel_id(id), do: Agent.cast(__MODULE__, &Map.replace!(&1, :id, id))

  def clean_channel, do: Agent.cast(__MODULE__, &remake_channel/1)

  defp remake_channel(%{id: nil} = state) do
    Api.create_message!(@admin_channel_id, "You forgot to set the selling channel id, dumbass")
    state
  end

  defp remake_channel(%{id: channel_id}) do
    with {:ok, _channel} <- Api.delete_channel(channel_id, "Nightly wipe"),
         {:ok, %{id: id}} <-
           Api.create_guild_channel(@guild_id,
             name: "selling-prices",
             parent_id: @channel_parent_id
           ) do
      %{id: id, prices: []}
    else
      {:error, error} ->
        %{response: %{message: message}, status_code: code} = error

        Api.create_message!(
          @admin_channel_id,
          "Something went wrong with deleting the selling channel: #{code} #{message}"
        )
    end
  end
end
