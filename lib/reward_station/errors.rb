module RewardStation

  module NestingError
    attr_reader :cause

    def initialize message = nil, cause = $!
      @cause = cause
      super(message || cause && cause.message)
    end

    def set_backtrace bt
      if cause
        cause.backtrace.reverse.each do |line|
          bt.last == line ? bt.pop : break
        end
        bt << "cause: #{cause.class.name}: #{cause}"
        bt.concat cause.backtrace
      end
      super bt
    end
  end

  class InvalidAccount < StandardError; end
  class InvalidToken < StandardError; end
  class InvalidUser < StandardError; end
  class UserAlreadyExists < StandardError; end
  class MissingInformation < StandardError; end
  class UnknownError < StandardError; end

  class ConnectionError < StandardError
    include NestingError
  end
end