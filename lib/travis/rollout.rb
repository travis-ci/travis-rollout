require 'zlib'

module Travis
  class Rollout
    class Env < Struct.new(:name)
      def enabled?
        names.include?(name.to_s)
      end

      def values(key)
        ENV["ROLLOUT_#{name.to_s.upcase}_#{key.to_s.upcase}S"].to_s.split(',')
      end

      def percent
        ENV["ROLLOUT_#{name.to_s.upcase}_PERCENT"]
      end

      def names
        ENV['ROLLOUT'].to_s.split(',')
      end
    end

    class RedisNoop
      def get(*); end
      def smembers(*); [] end
    end

    class Redis < Struct.new(:name, :redis)
      def enabled?
        redis.get(:"#{name}.rollout.enabled") == '1'
      end

      def percent
        redis.get(:"#{name}.rollout.percent")
      end

      def values(key)
        redis.smembers(:"#{name}.rollout.#{key}s")
      end

      def redis
        super || self.redis = RedisNoop.new
      end
    end

    class ByValue < Struct.new(:name, :key, :value, :env, :redis)
      def matches?
        !!value && values.include?(value)
      end

      def values
        values = redis.values(key)
        values = env.values(key) unless values.any?
        values
      end
    end

    class ByPercent < Struct.new(:name, :value, :env, :redis)
      def matches?
        !!value && value % 100 < percent
      end

      def percent
        percent = env.percent || redis.percent || -1
        percent.to_i
      end
    end


    def self.run(*all, &block)
      rollout = new(*all, &block)
      rollout.run if rollout.matches?
    end

    def self.matches?(*all)
      new(*all).matches?
    end

    attr_reader :name, :args, :block, :redis, :env

    def initialize(name, args, &block)
      @name  = name
      @args  = args
      @block = block
      @redis = Redis.new(name, args.delete(:redis) )
      @env   = Env.new(name)
    end

    def run
      block.call || true
    end

    def matches?
      enabled? and (by_value? or by_percent?)
    end

    private

      def enabled?
        env.enabled? || redis.enabled?
      end

      def by_value?
        by_values.map(&:matches?).inject(&:|)
      end

      def by_values
        args.map { |key, value| ByValue.new(name, key, value, env, redis) }
      end

      def by_percent?
        ByPercent.new(name, uid, env, redis).matches?
      end

      def uid
        uid = args[:uid]
        uid.is_a?(String) ? Zlib.crc32(uid).to_i & 0x7fffffff : uid
      end
  end
end
