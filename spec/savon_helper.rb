module Savon
  module Spec

    # = Savon::Spec::Macros
    #
    # Include this module into your RSpec tests to mock/stub Savon SOAP requests.
    module Macros
      def savon
        Savon::SOAP::Response.any_instance.stub(:soap_fault?).and_return(false)
        Savon::SOAP::Response.any_instance.stub(:http_error?).and_return(false)
        Savon::Spec::Mock.new
      end
    end

    class Fixture
      class << self

        def path
          @path ||= Rails.root.join("spec", "fixtures").to_s if defined? Rails

          raise ArgumentError, "Savon::Spec::Fixture.path needs to be specified" unless @path
          @path
        end

        attr_writer :path

        def load(*args)
          file = args.map { |arg| arg.to_s.snakecase }.join("/")
          fixtures[file] ||= load_file file
        end

        alias [] load

        private

        def fixtures
          @fixtures ||= {}
        end

        def load_file(file)
          full_path = File.expand_path File.join(path, "#{file}.xml")
          raise ArgumentError, "Unable to load: #{full_path}" unless File.exist? full_path

          File.read full_path
        end

      end
    end

    # = Savon::Spec::Mock
    #
    # Mocks/stubs SOAP requests executed by Savon.
    class Mock

      def expects(soap_action)
        setup :expects, soap_action
        self
      end

      def stub(soap_action)
        setup :stub, soap_action
        self
      end

      # Expects a given SOAP body Hash to be used.
      def with(soap_body)
        Savon::SOAP::XML.any_instance.expects(:body=).with(soap_body) if mock_method == :expects
        self
      end

      def never
        httpi_mock.never
        self
      end

      # Sets up HTTPI to return a given +response+.
      def and_return(response = nil)
        http = { :code => 200, :headers => {}, :body => "" }

        case response
          when Symbol   then http[:body] = Fixture[soap_action, response]
          when Hash     then http.merge! response
          when String   then http[:body] = response
        end

        httpi_mock.and_return HTTPI::Response.new(http[:code], http[:headers], http[:body])
        self
      end

      # Sets up Savon to respond like there was a SOAP fault.
      def raises_soap_fault
        Savon::SOAP::Response.any_instance.stub(:soap_fault?).and_return(true)
        self
      end

      def raises_http_error
        Savon::SOAP::Response.any_instance.stub(:soap_fault?).and_return(false)
        Savon::SOAP::Response.any_instance.stub(:http_error?).and_return(true)
        self
      end

      private

      def setup(mock_method, soap_action)
        self.mock_method = mock_method
        self.soap_action = soap_action
        self.httpi_mock = new_httpi_mock
      end

      attr_accessor :mock_method

      def soap_action=(soap_action)
        @soap_action = soap_action.kind_of?(Symbol) ? soap_action.to_s.lower_camelcase : soap_action
      end

      attr_reader :soap_action

      def new_httpi_mock
        HTTPI.send(mock_method, :post)
      end

      attr_accessor :httpi_mock

    end
  end
end
