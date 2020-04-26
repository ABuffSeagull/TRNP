defmodule Trnp.Patterns.SmallSpike do
  def calculate_ranges(base_price), do: Enum.map(0..7, &generate_pattern(&1, base_price))

  def generate_pattern(decreasing_length, base_price) do
    decreasing_stream = Stream.iterate({0.4, 0.9}, fn {min, max} -> {min - 0.05, max - 0.03} end)

    first_decrease = Enum.take(decreasing_stream, decreasing_length)
    second_decrease = Enum.take(decreasing_stream, 7 - decreasing_length)

    spike_interval = List.duplicate({0.9, 1.4}, 2) ++ List.duplicate({1.4, 2}, 3)

    (first_decrease ++ spike_interval ++ second_decrease)
    |> Enum.map(fn {min, max} -> {ceil(min * base_price), ceil(max * base_price)} end)
    |> List.update_at(decreasing_length + 2, fn {min, max} -> {min, max - 1} end)
    |> List.update_at(decreasing_length + 4, fn {min, max} -> {min, max - 1} end)
    |> Enum.map(fn {min, max} -> Range.new(min, max) end)
  end
end
