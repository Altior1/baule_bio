defmodule BauleBio.Repo do
  use Ecto.Repo,
    otp_app: :baule_bio,
    adapter: Ecto.Adapters.Postgres
end
