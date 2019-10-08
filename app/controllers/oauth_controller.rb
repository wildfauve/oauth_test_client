class OauthController < ApplicationController

  def authorisation_flow
    auth_service = IdentityAdapter.new.authorise_url(host: request.host_with_port)
    redirect_to auth_service
  end

end
