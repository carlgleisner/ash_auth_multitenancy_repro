defmodule Myapp.Repo do
  use AshPostgres.Repo,
    otp_app: :myapp

  import Ecto.Query, only: [from: 2]

  def installed_extensions do
    # Add extensions here, and the migration generator will install them.
    ["ash-functions", "citext"]
  end

  # Don't open unnecessary transactions
  # will default to `false` in 4.0
  def prefer_transaction? do
    false
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def all_tenants do
    all(from(row in "organizations", select: fragment("? || ?", "org_", row.subdomain)))
  end
end
