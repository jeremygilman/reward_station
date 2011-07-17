module Xceleration
  class InvalidAccount < StandardError; end
  class InvalidToken < StandardError; end
  class InvalidUser < StandardError; end
  class ConnectionError < StandardError;  end
  class UserAlreadyExists < StandardError; end

  class RewardStation

    PROGRAM_ID = 90
    POINT_REASON_CODE_ID = 129

    attr_reader :client

    def initialize
      @client = Savon::Client.new do |wsdl|
        wsdl.document = File.join(File.dirname(__FILE__), '..', 'wsdl', 'reward_services.xml')
      end
    end

    def return_token client_id, client_password
      result = request :return_token, :body => {
          'AccountNumber' => client_id,
          'AccountCode' => client_password
      }

      puts "xceleration token #{result[:token]}"

      result[:token]
    end

    def return_user token, xceleration_id
      result = request :return_user, :body => { 'UserID' => xceleration_id, 'Token' => token}
      result[:user_profile]
    end

    def award_points token, xceleration_id, points, description, program_id = PROGRAM_ID, point_reason_code_id = POINT_REASON_CODE_ID
      result = request :award_points, :body => {
          'UserID' => xceleration_id,
          'Points' => points,
          'ProgramID' => program_id,
          'PointReasonCodeID' => point_reason_code_id,
          'Description' => description,
          'Token' => token
      }
      result[:confirmation_number]
    end


    def return_point_summary token, xceleration_id, client_id
      result = request :return_point_summary, :body => {
          'clientId' => client_id,
          'userId' => xceleration_id,
          'Token' => token
      }
      result[:point_summary_collection][:point_summary]
    end

    def update_user token, xceleration_id, client_id, organization_id, attrs = {}

      email = attrs[:email] || ""
      first_name = attrs[:first_name] || ""
      last_name = attrs[:last_name] || ""
      user_name = attrs[:user_name] || email
      balance = attrs[:balance] || 0

      result = request :update_user , :body => {
          'updateUser' => {
              'UserID' => xceleration_id,
              'ClientID' => client_id,
              'UserName' => user_name,
              'FirstName' => first_name,
              'LastName' => last_name,
              'CountryCode' => 'USA',
              'Email' => email,
              'IsActive' => true,
              'PointBalance' => balance,
              'OrganizationID' => organization_id
          },
          'Token' => token
      }

      result[:update_user]
    end


    def create_user token, client_id, organization_id, attrs = {}
      update_user token, -1, client_id, organization_id, attrs
    end

    def return_popular_products token, xceleration_id
      result = request :return_popular_products , :body => {
          'userId' => xceleration_id,
          'Token' => token
      }

      result[:products][:product]
    end

    protected

    def request method_name, params

      response = @client.request(:wsdl, method_name , params).to_hash

      result = response[:"#{method_name}_response"][:"#{method_name}_result"]

      unless (error_message = result.delete(:error_message).to_s).nil?
        raise Xceleration::InvalidToken if error_message.start_with?("Invalid Token")
        raise Xceleration::InvalidAccount if error_message.start_with?("Invalid Account Number")
        raise Xceleration::InvalidUser if error_message.start_with?("Invalid User")
        raise Xceleration::UserAlreadyExists if error_message.start_with?("User Name:") && error_message.end_with?("Please enter a different user name.")
      end

      result
    rescue Savon::SOAP::Fault, Savon::HTTP::Error => ex
      puts ex.to_s
      puts ex.backtrace.inspect
      raise ConnectionError, ex.message
    end
  end
end