class TokenAdapter

  def call(client_id:, secret:, code:, redirect_uri:)
    get_token(client_id, secret, code, redirect_uri)
  end

  private

  def get_token(c, s, code, redirect_uri)
    result = token_service(client_auth(c,s)).(grant_req(code, redirect_uri))
    binding.pry "Get token failure" unless result.success?
    result.value_or.body["id_token"]
  end

  def grant_req(code, redirect_uri)
    {
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri,
      client_id: ENV['CLIENT_ID']
    }
  end

  def client_auth(c, s)
    net.basic_auth_header.(c,s)
  end

  def token_service(hdrs)
    net.post.(token_endpoint, "", hdrs, :url_encoded, F.identity)
  end

  def net
    Foucault::Net
  end

  def token_endpoint; ENV['TOKEN']; end

end
