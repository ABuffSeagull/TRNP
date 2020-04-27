defmodule Trnp.Patterns do
  @weights %{
    random: %{random: 0.2, large_spike: 0.3, decreasing: 0.15, small_spike: 0.35},
    large_spike: %{random: 0.5, large_spike: 0.05, decreasing: 0.2, small_spike: 0.25},
    decreasing: %{random: 0.25, large_spike: 0.45, decreasing: 0.05, small_spike: 0.25},
    small_spike: %{random: 0.45, large_spike: 0.25, decreasing: 0.15, small_spike: 0.15}
  }

  @patterns %{
    random: &Trnp.Patterns.Random.calculate_ranges/1,
    large_spike: &Trnp.Patterns.LargeSpike.calculate_ranges/1,
    decreasing: &Trnp.Patterns.Decreasing.calculate_ranges/1,
    small_spike: &Trnp.Patterns.SmallSpike.calculate_ranges/1
  }

  @spec match(pos_integer(), [pos_integer() | nil]) :: [
          {:random | :large_spike | :decreasing | :small_spike, [pos_integer | Range.t()],
           float()}
        ]
  def match(base_price, prices, last_pattern \\ :random) do
    patterns_map =
      Enum.map(@patterns, fn {type, fun} ->
        {type,
         base_price
         |> fun.()
         |> Enum.map(&Enum.zip(&1, prices))
         |> Enum.filter(&Enum.all?(&1, fn {range, price} -> is_nil(price) or price in range end))
         |> Enum.map(&Enum.map(&1, fn {range, price} -> price || range end))}
      end)

    counts = Enum.map(patterns_map, fn {type, patterns} -> {type, length(patterns)} end)

    added_weight =
      Enum.filter(counts, fn {_type, count} -> count == 0 end)
      |> Keyword.keys()
      |> Enum.map(&Map.fetch!(@weights[last_pattern], &1))
      |> Enum.sum()
      |> IO.inspect(label: "added weight")

    new_weights =
      Enum.map(@weights[last_pattern], fn {type, weight} -> {type, weight + added_weight} end)

    Enum.flat_map(patterns_map, fn {type, patterns} ->
      Enum.map(patterns, &{type, &1, new_weights[type] / Keyword.fetch!(counts, type)})
    end)
    |> Enum.sort_by(&elem(&1, 2))
    |> Enum.reverse()
  end
end
