defmodule Trnp.Patterns.Random do
  @spec generate_intervals() :: [
          [
            increasing: non_neg_integer(),
            decreasing: 2 | 3,
            increasing: non_neg_integer(),
            decreasing: 2 | 3,
            increasing: non_neg_integer()
          ]
        ]
  def generate_intervals do
    # Note: we build the intervals backwards
    0..6
    # Add first increase
    |> Enum.map(&[increasing: &1])
    # Add first decrease
    |> Enum.flat_map(&[[{:decreasing, 2} | &1], [{:decreasing, 3} | &1]])
    # Add both second and third increase
    |> Enum.flat_map(fn [_, increasing: inc_first] = list ->
      # Get temp value for second increase
      temp = 7 - inc_first

      # Calculate both second and third
      Enum.map(
        0..(temp - 1),
        &[{:increasing, &1}, {:increasing, temp - &1} | list]
      )
    end)
    # Add second decrease
    |> Enum.map(&List.insert_at(&1, 1, {:decreasing, 5 - Keyword.fetch!(&1, :decreasing)}))
    # Reverse it, since we built it backwards
    |> Enum.map(&Enum.reverse/1)
  end

  @spec calculate_ranges(pos_integer()) :: [[Range.t()]]
  def calculate_ranges(base_price) do
    generate_intervals()
    |> Enum.map(
      # Replace each :increasing/:decreasing with actual ranges
      &Enum.flat_map(&1, fn
        {:increasing, count} ->
          List.duplicate(bell_range(base_price, 0.9, 1.4), count)

        {:decreasing, count} ->
          0..(count - 1)
          # Find min and max percentages for each day
          |> Enum.map(fn day -> {0.6 - 0.1 * day, 0.8 - 0.04 * day} end)
          |> Enum.map(fn {min, max} -> bell_range(base_price, min, max) end)
      end)
    )
  end

  defp bell_range(base_price, lower_ratio, upper_ratio) do
    Range.new(ceil(base_price * lower_ratio), ceil(base_price * upper_ratio))
  end
end
