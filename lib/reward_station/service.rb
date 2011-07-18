module RewardStation
  class Service

    def new_token_callback &block
      @new_token_callback = block
    end

    def initialize options = {}
      [:client_id, :client_password].each do |arg|
        raise ArgumentError, "Missing required option '#{arg}'" unless options.has_key? arg
      end

      @client_id = options[:client_id]
      @client_password = options[:client_password]
      @token = options[:token]
      @organization_id = options[:organization_id]

      @program_id = options[:program_id]
      @point_reason_code_id = options[:point_reason_code_id]

      if options[:new_token_callback]
        raise ArgumentError, "new_token_callback option should be proc or lambda" unless options[:new_token_callback].is_a?(Proc)
        @new_token_callback = options[:new_token_callback]
      end

    end

    def self.client
      @@client ||= Savon::Client.new do |wsdl|
        wsdl.document = File.join(File.dirname(__FILE__), '..', 'wsdl', 'reward_services.xml')
      end
    end

    def return_token
      result = request :return_token, :body => {
          'AccountNumber' => @client_id,
          'AccountCode' => @client_password
      }

      puts "xceleration token #{result[:token]}"

      result[:token]
    end

    def return_user xceleration_id
      request_with_token(:return_user, :body => { 'UserID' => xceleration_id} )[:user_profile]
    end

    def award_points xceleration_id, points, description, program_id = nil, point_reason_code_id = nil
      request_with_token(:award_points, :body => {
          'UserID' => xceleration_id,
          'Points' => points,
          'ProgramID' => program_id || @program_id,
          'PointReasonCodeID' => point_reason_code_id || @point_reason_code_id,
          'Description' => description
      })[:confirmation_number]
    end


    def return_point_summary xceleration_id
      request_with_token(:return_point_summary, :body => {
          'clientId' => @client_id,
          'userId' => xceleration_id
      })[:point_summary_collection][:point_summary]
    end

    def update_user xceleration_id, attrs = {}

      organization_id = attrs[:organization_id] || @organization_id
      email = attrs[:email] || ""
      first_name = attrs[:first_name] || ""
      last_name = attrs[:last_name] || ""
      user_name = attrs[:user_name] || email
      balance = attrs[:balance] || 0

      request_with_token(:update_user , :body => {
          'updateUser' => {
              'UserID' => xceleration_id,
              'ClientID' => @client_id,
              'UserName' => user_name,
              'FirstName' => first_name,
              'LastName' => last_name,
              'CountryCode' => 'USA',
              'Email' => email,
              'IsActive' => true,
              'PointBalance' => balance,
              'OrganizationID' => organization_id
          }
      })[:update_user]
    end


    def create_user attrs = {}
      update_user -1, attrs
    end

    def return_popular_products xceleration_id
      request_with_token(:return_popular_products , :body => { 'userId' => xceleration_id} )[:products][:product]
    end

    protected

    def update_token
      @token = return_token
      @new_token_callback.call(@token) if @new_token_callback
    end

    def inject_token params
      (params[:body] ||= {})['Token'] = @token
    end

    def request_with_token method_name, params
      update_token unless @token
      inject_token params
      request method_name, params
    rescue InvalidToken
      update_token
      inject_token params
      request method_name, params
    end

    def request method_name, params
      response = Service.client.request(:wsdl, method_name , params).to_hash

      puts response.inspect

      result = response[:"#{method_name}_response"][:"#{method_name}_result"]

      unless (error_message = result.delete(:error_message).to_s).nil?
        raise InvalidToken if error_message.start_with?("Invalid Token")
        raise InvalidAccount if error_message.start_with?("Invalid Account Number")
        raise InvalidUser if error_message.start_with?("Invalid User")
        raise UserAlreadyExists if error_message.start_with?("User Name:") && error_message.end_with?("Please enter a different user name.")
      end

      result
    rescue Savon::SOAP::Fault, Savon::HTTP::Error => ex
      puts ex.to_s
      puts ex.backtrace.inspect
      raise ConnectionError.new
    end
  end
end
