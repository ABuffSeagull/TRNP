defmodule Trnp.Patterns do
  @spec match(pos_integer(), [pos_integer() | nil]) :: [[pos_integer | Range.t()]]
  def match(base_price, prices) do
    base_price
    |> Trnp.Patterns.Random.calculate_ranges()
    |> Enum.map(&Enum.zip(&1, prices))
    |> Enum.filter(&Enum.all?(&1, fn {range, price} -> is_nil(price) || price in range end))
    |> Enum.map(&Enum.map(&1, fn {range, price} -> price || range end))
  end
end
