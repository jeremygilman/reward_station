### Xceleration Reward Station


## Basic Usage


## SSO

    #session_controller

    require 'saml/auth_response'

    class SessionController < ApplicationController
      skip_before_filter :require_user, :only => [:new, :create, :signon]
      skip_before_filter :require_no_deactivated!

      def new
        return redirect_to(root_url) if current_user.present?
        @user_session = UserSession.new
      end

      def create
        @user_session = UserSession.new(params[:user_session])
        if @user_session.save
          if session[:saml_request].present?
            sso_params(session[:saml_request], session[:relay_state], current_user)
            session[:saml_request] = session[:relay_state] = nil
            render :template => "session/signon"
            return
          else
            redirect_to_landing_page
          end
        else
          render :action => :new
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

    # session/signon.html.erb

    <html>
      <body>
        <form method="post" action="<%= Settings.sso.sp_destination %>?binding=urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" id="sso_form">
          <input type="hidden" name="SAMLResponse" value="<%= @saml_response %>"/>
          <input type="hidden" name="RelayState" value="<%= @relay_state %>"/>
        </form>
        <script type="text/javascript">
          document.getElementById('sso_form').submit();
        </script>
      </body>
    </html>

