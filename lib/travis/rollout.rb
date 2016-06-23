require 'zlib'

module Travis
  class Rollout
    ENVS = %w(production staging)

    def self.run(*all, &block)
      rollout = new(*all, &block)
      rollout.run if rollout.matches?
    end

    attr_reader :args, :options, :block

    def initialize(args = {}, options = {}, &block)
      @args, @options, @block = args, options, block
    end

    def run
      block.call || true
    end

    def matches?
      production? and enabled? and (by_owner? or by_repo? or by_user? or by_percent?)
    end

    private

      def production?
        ENVS.include?(ENV['ENV'])
      end

      def enabled?
        !!ENV['ROLLOUT'] && (!redis || redis.get(:"#{name}.rollout.enabled") == '1')
      end

      def by_owner?
        !!owner && owners.include?(owner)
      end

      def owner
        args[:owner]
      end

      def owners
        read_collection('rollout', 'owners')
      end

      def by_repo?
        !!repo && repos.include?(repo)
      end

      def repo
        args[:repo]
      end

      def repos
        read_collection('rollout', 'repos')
      end

      def by_user?
        !!user && users.include?(user)
      end

      def user
        args[:user]
      end

      def users
        read_collection('rollout', 'users')
      end

      def by_percent?
        !!uid && uid % 100 < percent
      end

      def uid
        uid = args[:uid]
        uid.is_a?(String) ? Zlib.crc32(uid).to_i & 0x7fffffff : uid
      end

      def percent
        percent = ENV['ROLLOUT_PERCENT'] || redis && redis.get(:"#{name}.rollout.percent") || -1
        percent.to_i
      end

      def name
        ENV['ROLLOUT'].to_s.split('.').first
      end

      def redis
        options[:redis]
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
