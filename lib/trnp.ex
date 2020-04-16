defmodule Trnp do
  @moduledoc """
  A simple Application for the TRNP bot
  """

  use Application

  def start(_type, _args) do
    children = [
      Discord,
      Trnp.Selling,
      Scheduler
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
