# AshAuthentication Multitenancy Reproduction

## The Generated Project

The first commit is the project generated with:

```sh
sh <(curl 'https://ash-hq.org/new/myapp?install=phoenix') \
    && cd myapp && mix igniter.install ash_phoenix \
    ash_postgres ash_authentication \
    ash_authentication_phoenix ash_admin \
    --auth-strategy password --yes && mix ash.setup
```

The only change in the first commit is reading the database hostname from an environment variable in the Dev Container.

```elixir
hostname: System.get_env("DATABASE_HOST", "localhost"),
```

## Versions

- elixir `1.18.1`
- otp `27.2`
- ash `3.4.64`
- ash_admin `0.13.0`
- ash_authentication `4.5.1`
- ash_authentication_phoenix `2.4.7`
- ash_phoenix `2.1.18`
- ash_postgres `2.5.5`
- ash_sql `0.2.57`

## The multitenancy setup

In addition to the generated `User` and `Token` resources in the `Account` domain, there is an `Organization` resource to represent the tenanats.

The `Organization` resource uses the `:attribute` strategy for multitenancy through the `:subdomin` attribute, whereas the `User` and `Token` resources use the `:context` strategy for schema based multitenancy in Postgres.

**User and Token**

```elixir
multitenancy do
  strategy :context
end
```

**Organization**

```elixir
postgres do
  table "organizations"
  repo Myapp.Repo

  manage_tenant do
    template ["org_", :subdomain]
    create? true
    update? false
  end
end

multitenancy do
  strategy :attribute
  attribute :subdomain
  global? true
end
```

To juggle resources using different multitenancy strategies, the `Ash.ToTenant` protocol introspects the resources and returns either the `org_subdomain` form or the attrubute `subdomain`.

```elixir
defimpl Ash.ToTenant do
  def to_tenant(%{subdomain: subdomain}, resource) do
    if Ash.Resource.Info.data_layer(resource) == AshPostgres.DataLayer &&
          Ash.Resource.Info.multitenancy_strategy(resource) == :context do
      "org_#{subdomain}"
    else
      subdomain
    end
  end
end
```

Perhaps worth noting that the `:subdomain` attribute is of type `:ci_string`.

```elixir
attribute :subdomain, :ci_string do
  public? true
  allow_nil? false
end
```

## Seed data

The `seeds.exs` sets up a secrative organization:

```elixir
Myapp.Accounts.Organization
|> Ash.Changeset.for_create(:create, %{name: "NSA", subdomain: "nsa"})
|> Ash.create!()
```

With this organization, you can set the tenant in AshAdmin to `org_nsa`. As far as I can tell this is in and of itself fully functional.

## To reproduce

Spin up the old machine:

```sh
mix deps.get
mix ash.setup
mix run priv/repo/seeds.exs
iex -S mix phx.server
```

Try registering a user with password from AshAdmin on `http://localhost:4000/admin` having first set the tenant to `org_nsa`.

Looking at the log one finds the following:

```elixir
[debug] QUERY OK source="tokens" db=1.7ms
INSERT INTO "org_nsa"."tokens" AS t0 ("inserted_at","updated_at","created_at","expires_at","purpose","subject","jti") VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT ("jti") DO UPDATE SET "expires_at" = EXCLUDED."expires_at", "purpose" = EXCLUDED."purpose", "subject" = EXCLUDED."subject", "updated_at" = COALESCE(EXCLUDED."updated_at", $8) RETURNING "updated_at","inserted_at","extra_data","purpose","expires_at","subject","jti","created_at" [~U[2025-02-16 17:02:58.599209Z], ~U[2025-02-16 17:02:58.599209Z], ~U[2025-02-16 17:02:58.599206Z], ~U[2025-02-19 17:02:58Z], "user", "user?id=e6e250fa-ec7d-4522-a29d-bdd02dc94fac", "30ibu0te43ui20kdc00000j2", ~U[2025-02-16 17:02:58.599244Z]]
↳ AshPostgres.DataLayer.bulk_create/3, at: lib/data_layer.ex:1934
[error] Failed to generate confirmation token
: ** (Ash.Error.Invalid)
Bread Crumbs:
  > Error returned from: Myapp.Accounts.Token.store_confirmation_changes

Invalid Error

* Queries against the Myapp.Accounts.Token resource require a tenant to be specified
  (ash 3.4.63) lib/ash/error/invalid/tenant_required.ex:5: Ash.Error.Invalid.TenantRequired.exception/1
  (ash 3.4.63) lib/ash/actions/create/create.ex:600: Ash.Actions.Create.set_tenant/1
  (ash 3.4.63) lib/ash/actions/create/create.ex:253: Ash.Actions.Create.commit/3
  (ash 3.4.63) lib/ash/actions/create/create.ex:132: Ash.Actions.Create.do_run/4
  (ash 3.4.63) lib/ash/actions/create/create.ex:50: Ash.Actions.Create.run/4
  (ash_authentication 4.5.1) lib/ash_authentication/add_ons/confirmation/actions.ex:93: AshAuthentication.AddOn.Confirmation.Actions.store_changes/4
  (ash_authentication 4.5.1) lib/ash_authentication/add_ons/confirmation.ex:141: AshAuthentication.AddOn.Confirmation.confirmation_token/3
  (ash_authentication 4.5.1) lib/ash_authentication/add_ons/confirmation/confirmation_hook_change.ex:329: anonymous fn/4 in AshAuthentication.AddOn.Confirmation.ConfirmationHookChange.maybe_perform_confirmation/3
  (ash 3.4.63) lib/ash/changeset/changeset.ex:4066: anonymous fn/2 in Ash.Changeset.run_after_actions/3
  (elixir 1.18.1) lib/enum.ex:4964: Enumerable.List.reduce/3
  (elixir 1.18.1) lib/enum.ex:2600: Enum.reduce_while/3
  (ash 3.4.63) lib/ash/changeset/changeset.ex:3544: anonymous fn/3 in Ash.Changeset.with_hooks/3
  (ecto_sql 3.12.1) lib/ecto/adapters/sql.ex:1400: anonymous fn/3 in Ecto.Adapters.SQL.checkout_or_transaction/4
  (db_connection 2.7.0) lib/db_connection.ex:1756: DBConnection.run_transaction/4
  (ash 3.4.63) lib/ash/changeset/changeset.ex:3542: anonymous fn/3 in Ash.Changeset.with_hooks/3
  (ash 3.4.63) lib/ash/changeset/changeset.ex:3686: anonymous fn/2 in Ash.Changeset.transaction_hooks/2
  (ash 3.4.63) lib/ash/changeset/changeset.ex:3523: Ash.Changeset.with_hooks/3
  (ash 3.4.63) lib/ash/actions/create/create.ex:260: Ash.Actions.Create.commit/3
  (ash 3.4.63) lib/ash/actions/create/create.ex:132: Ash.Actions.Create.do_run/4
```

The same error appears when executing the code from the `iex` session:

```elixir
tenant = Myapp.Accounts.get_organization_by_subdomain!("nsa")

attrs = %{
  email: "john@nsa.gov",
  password: "asdfasdf",
  password_confirmation: "asdfasdf"
}

Myapp.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, attrs, tenant: tenant, authorize?: false)
|> Ash.create!()
```

There are records created for both the `User` and `Token` resources, but the actions appear non-functional in this configuration.
