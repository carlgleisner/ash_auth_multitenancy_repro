# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Myapp.Repo.insert!(%Myapp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Myapp.Accounts.Organization
|> Ash.Changeset.for_create(:create, %{name: "NSA", subdomain: "nsa"})
|> Ash.create!()
