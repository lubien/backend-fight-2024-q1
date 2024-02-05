defmodule BackendFight.Repo do
  use Ecto.Repo,
    otp_app: :backend_fight,
    adapter: Ecto.Adapters.SQLite3
end
