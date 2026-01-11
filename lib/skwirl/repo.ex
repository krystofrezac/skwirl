defmodule Skwirl.Repo do
  use Ecto.Repo,
    otp_app: :skwirl,
    adapter: Ecto.Adapters.Postgres
end
