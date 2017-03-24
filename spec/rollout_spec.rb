require 'redis'
require 'travis/rollout'

describe Travis::Rollout do
  let(:redis) { Redis.new }
  let(:env)   { %w(ENV ROLLOUT ROLLOUT_#{name.upcase}_OWNERS ROLLOUT_#{name.upcase}_REPOS ROLLOUT_#{name.upcase}_USERS ROLLOUT_#{name.upcase}_PERCENT) }

  after   { redis.flushall }
  after   { env.each { |key| ENV.delete(key) } }
  subject { rollout.matches? }

  shared_examples_for 'matches by owner name' do
    context 'matches if the given owner name matches the OWNERS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_OWNERS"] = owner }
      it { should eq true }
    end

    context 'matches if the given owner name matches the redis key [name].rollout.owners' do
      before { redis.sadd("#{name}.rollout.owners", owner) }
      it { should eq true }
    end
  end

  shared_examples_for 'does not match by owner name' do
    context 'does not match even if the given owner name matches the OWNERS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_OWNERS"] = owner }
      it { should eq false }
    end

    context 'does not match even if the given owner name matches the redis key [name].rollout.owners' do
      before { redis.sadd("#{name}.rollout.owners", owner) }
      it { should eq false }
    end
  end

  shared_examples_for 'matches by repo slug' do
    context 'matches if the given repo slug matches the REPOS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_REPOS"] = repo }
      it { should eq true }
    end

    context 'matches if the given repo slug matches the redis key [name].rollout.repos' do
      before { redis.sadd("#{name}.rollout.repos", repo) }
      it { should eq true }
    end
  end

  shared_examples_for 'does not match by repo slug' do
    context 'does not match even if the given repo slug matches the REPOS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_REPOS"] = repo }
      it { should eq false }
    end

    context 'does not match even if the given repo slug matches the redis key [name].rollout.repos' do
      before { redis.sadd("#{name}.rollout.repos", repo) }
      it { should eq false }
    end
  end

  shared_examples_for 'matches by user name' do
    context 'matches if the given user name matches the REPOS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_USERS"] = user }
      it { should eq true }
    end

    context 'matches if the given user name matches the redis key [name].rollout.users' do
      before { redis.sadd("#{name}.rollout.users", user) }
      it { should eq true }
    end
  end

  shared_examples_for 'does not match by user name' do
    context 'does not match even if the given user slug matches the REPOS env var' do
      before { ENV["ROLLOUT_#{name.upcase}_USERS"] = user }
      it { should eq false }
    end

    context 'does not match even if the given user name matches the redis key [name].rollout.users' do
      before { redis.sadd("#{name}.rollout.users", user) }
      it { should eq false }
    end
  end

  shared_examples_for 'matches by percentage' do
    context 'matches if the given id matches the ROLLOUT_PERCENT env var' do
      before { ENV["ROLLOUT_#{name.upcase}_PERCENT"] = '100' }
      it { should eq true }
    end

    context 'matches if the given id matches the redis key [name].rollout.percent' do
      before { redis.set("#{name}.rollout.percent", 100) }
      it { should eq true }
    end
  end

  shared_examples_for 'does not match by percentage' do
    context 'does not match even if the given id matches the ROLLOUT_PERCENT env var' do
      before { ENV["ROLLOUT_#{name.upcase}_PERCENT"] = '100' }
      it { should eq false }
    end

    context 'does not match even if the given id matches the redis key [name].rollout.percent' do
      before { redis.set("#{name}.rollout.percent", 100) }
      it { should eq false }
    end
  end

  shared_examples_for 'matches by' do |type|
    context 'with ROLLOUT being set to another name' do
      before { ENV['ENV'] = 'production' }
      before { ENV['ROLLOUT'] = 'something_else' }
      include_examples "does not match by #{type}"
    end

    context 'with ROLLOUT being set to another name, but [name].rollout.enabled being set in redis' do
      before { ENV['ENV'] = 'production' }
      before { ENV['ROLLOUT'] = 'something_else' }
      before { redis.set("#{name}.rollout.enabled", '1') }
      include_examples "matches by #{type}"
    end

    context 'with ROLLOUT being set in production' do
      before { ENV['ENV'] = 'production' }
      before { ENV['ROLLOUT'] = name }
      include_examples "matches by #{type}"
    end

    context 'with ROLLOUT being set in staging' do
      before { ENV['ENV'] = 'production' }
      before { ENV['ROLLOUT'] = name }
      include_examples "matches by #{type}"
    end

    context 'with ROLLOUT being set in development' do
      before { ENV['ENV'] = 'development' }
      before { ENV['ROLLOUT'] = name }
      include_examples "does not match by #{type}"
    end

    context 'with ROLLOUT not set in production' do
      before { ENV['ENV'] = 'production' }
      include_examples "does not match by #{type}"
    end
  end

  # Gatekeeper knows an event uuid, an owner name, and a repo name
  describe 'as used in gatekeeper' do
    let(:name)    { 'gator' }
    let(:id)      { '517be336-f16d-45cf-aa9b-a429547af6ad' }
    let(:owner)   { 'carlad' }
    let(:repo)    { 'travis-ci/travis-hub' }
    let(:rollout) { described_class.new(name, uid: id, owner: owner, repo: repo, redis: redis) }

    include_examples 'matches by', 'owner name'
    include_examples 'matches by', 'repo slug'
    include_examples 'matches by', 'percentage'
  end

  # Sync knows a user id, or repo id
  describe 'as used in sync' do
    let(:name) { 'sync' }

    describe 'in the user sync worker' do
      let(:id)      { 1 }
      let(:user)    { 'carlad' }
      let(:rollout) { described_class.new(name, uid: id, user: user, redis: redis) }

      include_examples 'matches by', 'user name'
      include_examples 'matches by', 'percentage'
    end

    describe 'in the repo branches sync worker' do
      let(:id)      { 1 } # user id
      let(:owner)   { 'carlad' }
      let(:rollout) { described_class.new(name, uid: id, owner: owner, redis: redis) }

      include_examples 'matches by', 'owner name'
      include_examples 'matches by', 'percentage'
    end
  end
end
