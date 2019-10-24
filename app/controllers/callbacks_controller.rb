class CallbacksController < ApplicationController

  def redirect
    # Get an access token for the logged_in user from the ID Service using an OAuth /token call
    # Now we need to create an internal "user" by getting the /me
    @auth = Oauth2Coordinator.new.get_access(params: params, host: request.host_with_port)
  end

end
