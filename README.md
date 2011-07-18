### Xceleration Reward Station


## Basic Usage

#Initialization
    reward_station = RewardStation::Service.new :client_id => "112112", :client_password => "fsdftr#"

# Return Token
Request access token

    reward_station.return_token

# Award Points
Update award points

    user_id = "130"
    points = 10
    description = "Action 'Call to client' "
    program_id = 90 #optional
    point_reasond_code_id = 129 #optional
    reward_station.award_points user_id, points, description, program_id, point_reason_code_id


## Single-Sign-On

Basic SSO logic implemented in SAML::AuthResponse class. Example usage of AuthResponse:

#SessionController

    require 'saml/auth_response'

    class SessionController < ApplicationController

      def create
        @user_session = UserSession.new(params[:user_session])
        if @user_session.save
            if session[:saml_request].present?
                sso_params(session[:saml_request], session[:relay_state], current_user)
                session[:saml_request] = session[:relay_state] = nil
                render :template => "session/signon"
                return
             ...
            end
          ...
        end
      end

      def signon
        if current_user.present?
          sso_params(params[:SAMLRequest], params[:RelayState], current_user)

          render :template => "session/signon"
        else
          session[:saml_request] = params[:SAMLRequest]
          session[:relay_state] = params[:RelayState]
          redirect_to signin_url
        end
      end

      def destroy
        current_user_session.destroy
        redirect_to signin_url
      end

      protected

      def sso_params saml_request, relay_state, user
        @saml_response = SAML::AuthResponse.new(saml_request).response_url(user.xceleration_id)
        @relay_state = relay_state
      end
    end

# signon.html.erb

    <html>
      <body>
        <form  id="sso_form" action="http://www6.rewardstation.net/sso/100080/AssertionService.aspx?binding=urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" method="post">
          <input type="hidden" name="SAMLResponse" value="<%= @saml_response %>"/>
          <input type="hidden" name="RelayState" value="<%= @relay_state %>"/>
        </form>
        <script type="text/javascript">
          document.getElementById('sso_form').submit();
        </script>
      </body>
    </html>

