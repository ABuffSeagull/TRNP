defmodule Trnp.Buying do
  use Agent

  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @selling_channel_id Application.fetch_env!(:trnp, :selling_channel_id)

  @price_regex ~r/price:(\s+)?(?<bells>\d+)/i

  def start_link(initial_messages) do
    Agent.start_link(fn -> initial_messages end, name: __MODULE__)
  end

  def update(%Message{id: message_id, content: content}),
    do: Agent.cast(__MODULE__, &update_agent(&1, message_id, content))

  defp update_agent(messages, id, content) do
    price =
      Regex.run(@price_regex, content, capture: ["bells"])
      |> List.first()
      |> String.to_integer()

    messages =
      [{price, id} | messages]
      |> Enum.sort(fn {price1, _}, {price2, _} -> price1 < price2 end)

    [{lowest_price, _} | _] = messages

    Api.create_message(@selling_channel_id, "Lowest price is #{lowest_price} bells")

    messages
  end

  def get_lowest(amount) do
    Agent.get(__MODULE__, &Enum.slice(&1, 0, amount))
  end

  def get_all, do: Agent.get(__MODULE__, & &1)

  def reset() do
    Agent.cast(__MODULE__, fn -> [] end)
    # TODO: delete all messages in channel
  end
end
