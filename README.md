### Xceleration Reward Station

Client library for Xceleration rewardstation.com SOAP service

## Basic Usage

Common scenario is creating client instance using required parameters :client_id and :client_password.
Client implements several methods for accessing reward station SOAP API.

# Initialization
    reward_station = RewardStation::Client.new :client_id => "112112",                      # required
                                               :client_password => "fsdftr#",               # required
                                               :organization_id => '150',                   # optional, default Organization ID
                                               :program_id => 25,                           # optional, default Program ID
                                               :point_reasond_code_id => 129                # optional, default Point Reason Code ID
                                               :token => "sdfweqwrtwerfasdfas"              # optional, initial Access Token value
                                               :new_token_callback => lambda{|token| ... }   # optional, callback on Access Token change

# New Token Callback
You can specify callback in constructor as `lambda` or `proc`
Or you can specify callback as block:

    reward_station.new_token_calback do |new_token|
        # notify other client instance about new token
    end

# Return Token
Request access token

    token = reward_station.return_token

# Update Token Callback
    reward_station = RewardStation::Client.new :client_id => "112112",
                                               :client_password => "fsdftr#",
                                               :rew



# Award Points
Update award points

    user_id = "130"
    points = 10
    description = "Action 'Call to client' "
    program_id = 90 # optional
    point_reasond_code_id = 129 # optional

    confirmation_number = reward_station.award_points user_id, points, description, program_id, point_reason_code_id

# Create User

    user_attributes = reward_station.create_user :organization_id => '150',
                                                 :email => 'john5@company.com',
                                                 :first_name => 'John',
                                                 :last_name => 'Smith',
                                                 :user_name => 'john5@company.com',
                                                 :balance => 0
    puts user_attributes.inspect
    # {
    #    :user_id => '6727',
    #    :client_id => '100080',
    #    :user_name => 'john5@company.com',
    #    :email => 'john5@company.com',
    #    :encrypted_password => nil,
    #    :first_name => 'John',
    #    :last_name => 'Smith',
    #    :address_one => nil,
    #    :address_two => nil,
    #    :city => nil,
    #    :state_code => nil,
    #    :province => nil,
    #    :postal_code => nil,
    #    :country_code => 'USA',
    #    :phone => nil,
    #    :organization_id => '150',
    #    :organization_name => nil,
    #    :rep_type_id => '0',
    #    :client_region_id => '0',
    #
    #    :is_active => true,
    #    :point_balance => '0',
    #    :manager_id => '0',
    #    :error_message => nil
    # }

## Stub Client

Client supports stub mode. Stub supports all request methods supported by `RewardStation::Client`
Stub client don't make requests to Reward Station API. It just returns predefined SOAP responses.
You can override those responses in `config/reward_station/responses` folder.
For example if `award_points` method response should be overridden then add `award_points.xml` file to `config/reward_station/responses` folder.

# Stub Initialization

    stub = RewardStation::Client.stub

#config/reward_station/responses/award_points.xml

    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
       <soap:Body>
          <AwardPointsResponse xmlns="http://rswebservices.rewardstation.com/">
             <AwardPointsResult>
                <UserID>577</UserID>
                <Points>10</Points>
                <ConfirmationNumber>9376</ConfirmationNumber>
                <ErrorMessage/>
             </AwardPointsResult>
          </AwardPointsResponse>
       </soap:Body>
    </soap:Envelope>


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

