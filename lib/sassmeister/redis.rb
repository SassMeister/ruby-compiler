require 'redis'

module SassMeister
  class RedisConnection
    def self.connect
      @connection ||= begin
        uri = URI.parse(ENV['REDISCLOUD_URL'] || ENV['REDIS_URL'] || 'redis://localhost:6379')
        ::Redis.new(host: uri.host, port: uri.port, password: uri.password)
      end
    end
  end

  class Redis
    attr_reader :value

    def initialize(key)
      @key = key
      get
    end

    def merge!(incoming)
      if incoming.is_a? String
        incoming = JSON.parse(incoming, symbolize_names: true) rescue incoming
      end

      @value.merge! incoming

      set
    end

    def get
      value = RedisConnection.connect.get @key
      @value = value ? (JSON.parse(value, symbolize_names: true) rescue value) : {}
    end

    def set(value = @value)
      unless value.is_a? String
        value = value.to_json
      end

      RedisConnection.connect.set @key, value
    end
  end
end

