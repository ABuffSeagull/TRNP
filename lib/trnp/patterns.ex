defmodule Trnp.Patterns do
  @spec match(pos_integer(), [pos_integer() | nil]) :: [[pos_integer | Range.t()]]

  @patterns %{
    random: &Trnp.Patterns.Random.calculate_ranges/1,
    large_spike: &Trnp.Patterns.LargeSpike.calculate_ranges/1
  }

  def match(base_price, prices) do
    Enum.flat_map(@patterns, fn {type, fun} ->
      base_price
      |> fun.()
      |> Enum.map(&Enum.zip(&1, prices))
      |> Enum.filter(&Enum.all?(&1, fn {range, price} -> is_nil(price) || price in range end))
      |> Enum.map(&Enum.map(&1, fn {range, price} -> price || range end))
      |> Enum.map(&{type, &1})
    end)
  end
end
