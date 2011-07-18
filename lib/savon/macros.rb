module Savon
  # = Savon::Spec::Macros
  #
  # Include this module into your RSpec tests to mock/stub Savon SOAP requests.
  module Macros
    def savon
      Savon::SOAP::Response.any_instance.stub(:soap_fault?).and_return(false)
      Savon::SOAP::Response.any_instance.stub(:http_error?).and_return(false)
      Savon::Mock.new
    end
  end
end