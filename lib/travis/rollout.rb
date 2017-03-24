require 'zlib'

module Travis
  class Rollout
    class RedisNoop
      def get(*); end
      def smembers(*); end
    end

    class ByValue < Struct.new(:name, :key, :value, :redis)
      def matches?
        !!value && values.include?(value)
      end

      def values
        values = redis.smembers(:"#{name}.rollout.#{key}s")
        values.any? ? values : ENV["ROLLOUT_#{key.to_s.upcase}S"].to_s.split(',')
      end
    end

    class ByPercent < Struct.new(:name, :value, :redis)
      def matches?
        !!value && value % 100 < percent
      end

      def percent
        percent = ENV['ROLLOUT_PERCENT'] || redis.get(:"#{name}.rollout.percent") || -1
        percent.to_i
      end
    end

    ENVS = %w(production staging)

    def self.run(*all, &block)
      rollout = new(*all, &block)
      rollout.run if rollout.matches?
    end

    def self.matches?(*all)
      new(*all).matches?
    end

    attr_reader :key, :args, :redis

    def initialize(key, args, &block)
      @key   = key
      @args  = args
      @block = block
      @redis = args.delete(:redis) || RedisNoop.new
    end

    def run
      block.call || true
    end

    def matches?
      production? and enabled? and (by_value? or by_percent?)
    end

    private

      def production?
        ENVS.include?(ENV['ENV'])
      end

      def enabled?
        !!ENV['ROLLOUT'] && (ENV['ROLLOUT'] == name || redis.get(:"#{name}.rollout.enabled") == '1')
      end

      def by_owner?
        !!owner && owners.include?(owner)
      end

      def owner
        args[:owner]
      end

      def owners
        owners = redis && redis.smembers(:"#{name}.rollout.owners")
        owners.any? ? owners : ENV["ROLLOUT_OWNERS"].to_s.split(',')
      end

      def by_repo?
        !!repo && repos.include?(repo)
      end

      def repo
        args[:repo]
      end

      def repos
        repos = redis && redis.smembers(:"#{name}.rollout.repos")
        repos.any? ? repos : ENV["ROLLOUT_REPOS"].to_s.split(',')
      end

      def by_user?
        !!user && users.include?(user)
      end

      def user
        args[:user]
      end

      def by_value?
        matchers.map(&:matches?).inject(&:|)
      end

      def users
        users = redis && redis.smembers(:"#{name}.rollout.users")
        users.any? ? users : ENV["ROLLOUT_USERS"].to_s.split(',')
      end

      def matchers
        args.map { |key, value| ByValue.new(name, key, value, redis) }
      end

      def by_percent?
        ByPercent.new(name, uid, redis).matches?
      end

      def uid
        uid = args[:uid]
        uid.is_a?(String) ? Zlib.crc32(uid).to_i & 0x7fffffff : uid
      end

      def name
        ENV['ROLLOUT'].to_s.split('.').first
      end

      def camelize(string)
        string.to_s.sub(/./) { |char| char.upcase }
      end

      def read_collection(*path)
        redis_path = path.map(&:downcase).join('.')
        env_key = path.map(&:upcase).join('_')
        if redis
          redis_collection = redis.smembers(:"#{name}.#{redis_path}")
          return redis_collection if redis_collection.any?
        end
        ENV.fetch(env_key, '').to_s.split(',')
      end
  end
end
