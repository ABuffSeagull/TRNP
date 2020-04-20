import Config

config :logger,
  level: :info

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :trnp, Scheduler,
  jobs: [
    channel_remake: [
      schedule: "@weekly",
      task: {Trnp.Selling, :clean_channel, []},
      timezone: "America/Los_Angeles"
    ]
  ]

import_config "#{Mix.env()}.secret.exs"
