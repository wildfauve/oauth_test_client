class IdentityJwksAdapter

  include Dry::Monads::Result::Mixin

  IDENTITY_JWKS = :identity_jwks
  CACHE_EXPIRY  = 1.day

  def call(decoded_jwt)
    Success(nil).bind do
      get_public_key_and_cache(decoded_jwt)
    end.or do |error|
      Failure(error)
    end
  end

  private

  def get_public_key_and_cache(decoded_jwt)
    result = from_cache(decoded_jwt, on_miss: refresh_jwk(decoded_jwt))
    result.present? ? Success(result) : Failure(result)
  end

  # The on_miss cache function
  def refresh_jwk(decoded_jwt)
    -> value {
      jwk = public_key_from_jwk(decoded_jwt)
      cached_jwks = value ? value.merge(jwk["kid"] => jwk) : {jwk["kid"] => jwk}
      {value: cached_jwks, expires_in: CACHE_EXPIRY}
    }
  end

  def public_key_from_jwk(decoded_jwt)
    # TODO: when get_keys returns a failure monad???
    ( F.find.(F.equality.(Crypto::KEY_FINGERPRINT).(decoded_jwt.header[Crypto::KEY_FINGERPRINT])) <<
    F.at.("keys") <<
    F.lift_monad).(get_keys)
  end

  def get_keys
    result = port.get.(identity_jwks_endpoint, "", {}, nil, {})
    result.success? ? Success(result.value_or.body) : result
  end

  def from_cache(decoded_jwt, on_miss:)
    result = cache.read(IDENTITY_JWKS, on_miss: on_miss)
    if result.present? && result.has_key?(decoded_jwt.header["kid"])
      result[decoded_jwt.header["kid"]]
    else
      nil
    end
  end

  def cache
    @cache ||= IC['util.cache'].init(IC['util.credential_store'], self.class.name)
  end

  def port
    IC['foucault.network']
  end

  def identity_jwks_endpoint
    ENV['JWKS_ENDPOINT']
  end

end
