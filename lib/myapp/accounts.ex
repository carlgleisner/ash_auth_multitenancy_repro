defmodule Myapp.Accounts do
  use Ash.Domain, otp_app: :myapp, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Myapp.Accounts.Organization do
      define :get_organization_by_subdomain, action: :read, get_by: :subdomain
    end

    resource Myapp.Accounts.Token
    resource Myapp.Accounts.User
  end
end
