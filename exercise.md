Refactor the class `Travis::Rollout` and remove the duplication of the methods
`by_[owner|repo|user]?`, `[owner|repo|user]s` etc.

Doing so also allow arbirary `args` hash to be passed:

```
args = {
  uid:  1
  user: 'carlad',
  repo: 'travis-hub'
  foo:  'bar'
}

Rollout.reroute(args) do
  # reroute the message
end

```

This would:

* Match the `uid` against the percentage.
* Not match the `uid` against the env var `ROLLOUT_UID` (i.e. ignore this case)
* Match the strings `carlad`, `travis-hub` and `bar` against the respective env
  vars `ROLLOUT_USERS`, `ROLLOUT_REPOS`, and `ROLLOUT_FOOS`
