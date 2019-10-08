class IdentityAdapter

  attr_accessor :access_token, :id_token, :id_token_encoded, :user_proxy

  include Rails.application.routes.url_helpers

  def authorise_url(host: nil, scope: nil)
    q = {}
    q[:response_type] = "code"
    q[:redirect_uri] = redirect_callbacks_url(host: host)
    q[:scope] = scope
    q[:client_id] = ENV['CLIENT_ID']
    "#{ENV['AUTHORISE']}?#{q.to_query}"
  end

  def logout_url(user_proxy: nil, host: nil)
    q = {post_logout_redirect_uri: url_helpers.root_url(host: host)}
    q[:id_token_hint] = user_proxy.access_token["id_token"]
    "#{Setting.oauth(:id_logout_service_url)}?#{q.to_query}"
  end

  #POST /token HTTP/1.1
  #   Host: server.example.com
  #   Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
  #   Content-Type: application/x-www-form-urlencoded
  #
  #   grant_type=authorization_code&code=SplxlOBeZQQYbYS6WxSbIA
  #   &redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb

  def get_access(params: nil, host:)
    jwt = TokenAdapter.new.(client_id: ENV['CLIENT_ID'], secret: ENV['CLIENT_SECRET'], code: params[:code], redirect_uri: redirect_callbacks_url(host: host))
    validate_id_token(jwt)
  end

  def validate_id_token(token)
    IC['util.crypto'].decode_jwt(token)
  end

  def id_token_provided?
    @id_token ? true : false
  end

  def get_claim(type: nil, key: nil)
    @id_token[type].first {|c| c["ref"] == "party"}
  end


end
