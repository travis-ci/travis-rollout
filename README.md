# travis-rollout

Enable by setting an env var `ROLLOUT` and setting `ENV` to `production` or
`staging`.

## Usage

```
args = { uid: 1, user: 'svenfuchs', repo: 'travis-hub' }
Travis::Rollout.run(args) do
  # reroute the message
end

```

This will match:

* uid against the percentage `ROLLOUT_PERCENT`
* remaining arg values against the env vars `ROLLOUT_USERS` and `ROLLOUT_REPOS` (as comma separated values)

`uid` can be a string or integer. For a string it will calculate the crc32 to
turn it into an integer.

If a redis instance is passed as an option it will additionally check redis:

```
Travis::Rollout.run(args, redis: redis) do
  # reroute the message
end
```

It will use the value of the env var `ROLLOUT` as a namespace (e.g. `sync`), and check the keys:

* enabling: `sync.rollout.enabled`
* args: `sync.rollout.users`, `sync.rollout.repos`, `sync.rollout.owners`
* percentage: `sync.rollout.percent`
