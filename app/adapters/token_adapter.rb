class TokenAdapter

  def call(client_id:, secret:, code:, code_verifier: nil, redirect_uri:)
    get_token(client_id, secret, code, code_verifier, redirect_uri)
  end

  private

  def get_token(c, s, code, verifier, redirect_uri)
    result = token_service(client_auth(c, s, verifier)).(grant_request(code, verifier, redirect_uri))
    binding.pry unless result.success?
    result.value_or.body
  end

  def grant_request(code, verifier, redirect_uri)
    {
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri
    }.merge(verifier ? {code_verifier: verifier} : {client_id: ENV['CLIENT_ID']})
  end

  def client_auth(c, s, verifier)
    verifier ? {} : net.basic_auth_header.(c,s)
    # net.basic_auth_header.(c,s)
  end

  def token_service(hdrs)
    net.post.(token_endpoint, "", hdrs, :url_encoded, F.identity)
  end

  def net
    Foucault::Net
  end

  def token_endpoint; ENV['TOKEN']; end

end
