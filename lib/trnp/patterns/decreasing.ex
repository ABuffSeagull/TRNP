defmodule Trnp.Patterns.Decreasing do
  @spec calculate_ranges(pos_integer()) :: [[Range.t()]]
  def calculate_ranges(base_price) do
    pattern =
      0..11
      |> Enum.map(&{0.85 - 0.05 * &1, 0.9 - 0.03 * &1})
      |> Enum.map(fn {min, max} ->
        Range.new(ceil(min * base_price), ceil(max * base_price))
      end)

    [pattern]
  end
end
