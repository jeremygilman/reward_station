module RewardStation
  class StubResponse
    class << self

      def gem_responses_path
        File.join(File.dirname(__FILE__), "responses")
      end

      def local_responses_path
        File.expand_path('config/reward_station/responses') rescue nil
      end

      def load(*args)
        file = args.map { |arg| arg.to_s.snakecase }.join("/")
        responses[file] ||= load_response_file file
      end

      alias_method :[], :load

      private

      def responses
        @responses ||= {}
      end

      def load_response_file(file)
        file_path = nil

        if local_responses_path
          local_path = File.join(local_responses_path, "#{file}.xml")
          file_path = local_path if File.exist?(local_path)
        end

        unless file_path
          gem_path = File.join(gem_responses_path, "#{file}.xml")
          file_path = gem_path if File.exist?(gem_path)
        end

        raise ArgumentError, "Unable to load: #{file}" unless file_path

        File.read file_path
      end
    end
  end
end
