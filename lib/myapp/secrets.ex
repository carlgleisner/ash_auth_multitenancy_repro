defmodule Myapp.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Myapp.Accounts.User, _opts) do
    Application.fetch_env(:myapp, :token_signing_secret)
  end
end
