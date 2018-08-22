# travis-rollout

Enable by setting an env var `ROLLOUT` and setting `ENV` to `production` or
`staging`.

## Usage

```ruby
args = {
  uid:  1
  user: 'svenfuchs',
  repo: 'travis-ci/travis-hub'
}

Rollout.run(:feature, args) do
  # only runs when active
end
```

This will match:

* uid against the percentage `ROLLOUT_FEATURE_PERCENT`
* remaining arg values against the env vars `ROLLOUT_FEATURE_USERS` and `ROLLOUT_FEATURE_REPOS` (as comma separated values)

For example:

```
ROLLOUT=feature_foo
ROLLOUT_FEATURE_FOO_OWNERS=joecorcoran,svenfuchs
ROLLOUT_FEATURE_FOO_PERCENT=5
```

The `uid` passed can be a string or integer. For a string it will calculate the
crc32 to turn it into an integer.

If a redis instance is passed as an option it will additionally check redis:

```ruby
Travis::Rollout.run(feature, args.merge(redis: redis)) do
  # only runs when active
end
```

It will use the value of the env var `ROLLOUT` as a namespace (e.g. `sync`), and check the keys:

* enabling: `sync.rollout.enabled`
* args: `sync.rollout.users`, `sync.rollout.repos`, `sync.rollout.owners`
* percentage: `sync.rollout.percent`

Values stored in Redis will take precedence over values stored in the ENV.
