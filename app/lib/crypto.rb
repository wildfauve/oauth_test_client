class Crypto

  extend Dry::Monads::Try::Mixin

  KEY_FINGERPRINT = "kid"

  class << self

    def jwt_try_decode(jwt)
      Try() { decode_jwt(jwt) }.to_maybe
    end

    # Decodes any JWT created by Identity, checks the signature, and checks expiry (when a "exp" exists in the body)
    # It operates in 2 modes; JWK and RSA Public Key.  The JWK mode is the default, and is used when the JWT
    # includes a "kid" header indicating that the JWT was signed using the JWK method.
    # Otherwise we use the Identity RSA public key.
    #
    # @param jwt            serialed JWT
    # @param jwk_public_key an alternate public key in JWK format to be used instead of the identity public key
    def decode_jwt(jwt)
      return nil if jwt.nil?
      decoded_jwt = decode_jwt_and_skip_verification(jwt)           # decode first to expose the headers
      return unless decoded_jwt.success?
      if generated_by_jwk_sig_mode?(decoded_jwt.value_or)                    # "kid" present?
        decoded_jwt.value_or.verify!(identity_public_from_jwk(decoded_jwt.value_or))
      else
        decoded_jwt.value_or.verify!(identity_public_key)                    # otherwise, use the classic mode
      end
      jwt_expired?(decoded_jwt.value_or) ? nil : decoded_jwt.value_or
    end

    def generated_by_jwk_sig_mode?(jwt)
      jwt.header.has_key? KEY_FINGERPRINT
    end

    def decode_jwt_and_skip_verification(jwt)
      return None() if jwt.nil?
      Try() { JSON::JWT.decode(jwt, :skip_verification) }.to_maybe
    end

    # Calls identity obtain the JWK used to encode the token being verified (note, also applies caching in the adapter).
    def identity_public_from_jwk(decoded_jwt)
      result = IC['common.adapters.identity_jwks'].new.(decoded_jwt)
      if result.success?
        public_key_from_jwk(result.value_or)
      else
        Rails.logger.info("Crypto: JWK get failure sub: #{decoded_jwt["sub"]}, kid: #{decoded_jwt.header["kid"]}")
        nil
      end
    end

    def public_key_from_jwk(jwk)
      JSON::JWK.new(jwk).to_key
    end

    def identity_public_key
      OpenSSL::PKey::RSA.new(ENV['IDENTITY_JWT_PUBLIC_KEY'])
    end

    def jwt_expired?(decoded_jwt)
      decoded_jwt["exp"] ? decoded_jwt["exp"].to_i < Time.now.to_i : false
    end

  end


end
