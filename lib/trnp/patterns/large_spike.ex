defmodule Trnp.Patterns.LargeSpike do
  @spec calculate_ranges(pos_integer()) :: [[Range.t()]]
  def calculate_ranges(base_price) do
    generate_percentages()
    |> Enum.map(
      &Enum.map(&1, fn {min, max} -> Range.new(ceil(min * base_price), ceil(max * base_price)) end)
    )
  end

  @spec generate_percentages() :: [[{float(), float()}]]
  def generate_percentages do
    1..7
    |> Enum.map(
      &Enum.take(
        Stream.iterate({0.85, 0.90}, fn {min, max} -> {min - 0.05, max - 0.03} end),
        &1
      )
    )
    |> Enum.map(
      &(&1 ++
          spike_percentages() ++ List.duplicate({0.4, 0.9}, 7 - length(&1)))
    )
  end

  @spec spike_percentages() :: [{float(), float()}]
  defp spike_percentages, do: [{0.9, 1.4}, {1.4, 2.0}, {2.0, 6.0}, {1.4, 2.0}, {9.0, 1.4}]
end
