class OauthController < ApplicationController

  def authorisation_flow
    auth_service = Oauth2Coordinator.new.authorise_url(host: request.host_with_port, client_type: params[:client_type])
    redirect_to auth_service
  end

end
