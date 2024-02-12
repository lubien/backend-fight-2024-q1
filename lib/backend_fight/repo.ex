defmodule BackendFight.Repo.Local do
  use Ecto.Repo,
    otp_app: :backend_fight,
    adapter: Ecto.Adapters.SQLite3
end

defmodule BackendFight.Repo do
  use Litefs.Repo, local_repo: BackendFight.Repo.Local
end
