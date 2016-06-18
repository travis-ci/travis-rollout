require 'zlib'

module Travis
  class Rollout < Struct.new(:args, :options, :block)
    ENVS = %w(production staging)

    def self.run(*args, &block)
      rollout = new(*args, block)
      rollout.run if rollout.matches?
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

      def users
        users = redis && redis.smembers(:"#{name}.rollout.users")
        users.any? ? users : ENV["ROLLOUT_USERS"].to_s.split(',')
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
  end
end
