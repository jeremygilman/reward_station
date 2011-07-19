module RewardStation
  class StubClient < Client

    def initialize responses = {}
      @responses = {}
    end

    protected

    def get_response method_name, params
      response = StubResponse[method_name, method_name]

      raise ArgumentError, "Missing stub file for '#{method_name}' request" unless response

      hash = Nori.parse(response)

      raise ArgumentError, "Stub file for '#{method_name}' has incorrect format" unless hash.key?(:envelope) || hash[:envelope].key?(:body)

      hash[:envelope][:body]
    end
  end
end