class CredentialStore
  include Singleton

  attr_accessor :bearer_token, :bearer_token_expiry, :identity_jwks, :identity_jwks_expiry

end
