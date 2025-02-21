defmodule Myapp.Accounts.Organization do
  use Ash.Resource,
    otp_app: :my_app,
    domain: Myapp.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo Myapp.Repo

    # While you can change `update?` to `true` and have an automatic
    # tenant migration run to update the context based multitenancy
    # resources, destroying the organization record will not cause
    # the Postgres schema for the tenant to be dropped. While that
    # preserves the data, it also makes it impossible to create a
    # new tenant with the same ID until that schema is dropped.
    manage_tenant do
      template ["org_", :subdomain]
      create? true
      update? false
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: [:name]]
  end

  multitenancy do
    strategy :attribute
    attribute :subdomain
    global? true
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end

    attribute :subdomain, :ci_string do
      public? true
      allow_nil? false
    end

    timestamps()
  end

  identities do
    identity :subdomain, [:subdomain], all_tenants?: true
  end

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
end
