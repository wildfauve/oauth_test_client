app_container = Dry::Container.new

app_container.namespace('common') do
  namespace('adapters') do
    register('identity_jwks', -> { IdentityJwksAdapter } )
  end
end

app_container.namespace('foucault') do
  register('network', -> { Foucault::Net } )
end

# concerned with common sharable functions
app_container.namespace('util') do
  register('crypto', -> { Crypto } )
  register('credential_store', -> { CredentialStore } )
  register('cache', -> { CacheWrapper } )
end


IC = app_container
