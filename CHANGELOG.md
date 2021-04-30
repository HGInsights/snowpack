## [0.1.4](https://github.com/HGInsights/snowpack/compare/v0.1.3...v0.1.4) (2021-04-30)


### Bug Fixes

* set the default idle_interval to 5 min (#9) ([67edb80](https://github.com/HGInsights/snowpack/commit/67edb8056a5e85a57a8b0985cfad9783777297f4)), closes [#9](https://github.com/HGInsights/snowpack/issues/9)


### Chores

* **ci:** refactor ci and Earthfile to configure elixir, erlang, ubuntu, and snowflake versions via args (#7) ([3e39531](https://github.com/HGInsights/snowpack/commit/3e3953193d2221471f279784cc34fd085b1897d3)), closes [#7](https://github.com/HGInsights/snowpack/issues/7)

## [0.1.3](https://github.com/HGInsights/snowpack/compare/v0.1.2...v0.1.3) (2021-04-16)


### Bug Fixes

* provide a default idle_interval of 3600 sec to be used as a session keepalive (#6) ([4a54529](https://github.com/HGInsights/snowpack/commit/4a54529a945352e1a6147a79efe827e0f8cb9836)), closes [#6](https://github.com/HGInsights/snowpack/issues/6)

## [0.1.2](https://github.com/HGInsights/snowpack/compare/v0.1.1...v0.1.2) (2021-04-13)


### Bug Fixes

* started adding more tests for queries (#3) ([d3f4c3d](https://github.com/HGInsights/snowpack/commit/d3f4c3d1b16b46dac3108f0825b6cb2edda4ef79)), closes [#3](https://github.com/HGInsights/snowpack/issues/3)

## [0.1.1](https://github.com/HGInsights/snowpack/compare/v0.1.0...v0.1.1) (2021-03-25)


### Bug Fixes

* parse zero-precision NUMBER types from Snowflake as integers, rather than decimals (#4) ([85d1665](https://github.com/HGInsights/snowpack/commit/85d1665fbf5762668249ca8fc5031640367d6d62)), closes [#4](https://github.com/HGInsights/snowpack/issues/4)


### Chores

* **ci:** fix next-version output var name ([9c8140c](https://github.com/HGInsights/snowpack/commit/9c8140c2894fa44204e56a051a6083bad0a69bb8))

# [0.1.0](https://github.com/HGInsights/snowpack/compare/v0.0.2...v0.1.0) (2021-03-17)


### Features

* release 0.1.0 and docs cleanup ([6048141](https://github.com/HGInsights/snowpack/commit/6048141110d1e8558e83befa2103505de74b6b05))

## [0.0.2](https://github.com/HGInsights/snowpack/compare/v0.0.1...v0.0.2) (2021-03-17)


### Bug Fixes

* use UTF-8 binary encoding and handle unknown column types (#2) ([3c3c55b](https://github.com/HGInsights/snowpack/commit/3c3c55b942f345540c40e35ae6cc7013d6639cd9)), closes [#2](https://github.com/HGInsights/snowpack/issues/2)


### Chores

* fix CHANGELOG version ([b94b857](https://github.com/HGInsights/snowpack/commit/b94b857947b44a612f949ee3b30bff16dd492e59))

# 0.0.1 (2021-03-11)

### Chores

- github actions, credo, ex_docs, semantic release
  ([1f12897](https://github.com/HGInsights/snowpack/commit/1f128971979feb56c086aeed2dd1a47ee6741c22))
- new app ([f352e61](https://github.com/HGInsights/snowpack/commit/f352e617070cb7e2943eae4f9043ad452b5a836f))

### Features

- implement basic DBConnection query behavior (#1)
  ([5f164e9](https://github.com/HGInsights/snowpack/commit/5f164e98f89897eb6b28b56fefbe168c9f5f7f24)), closes
  [#1](https://github.com/HGInsights/snowpack/issues/1)

- Initial commit ([9e5a9ba](https://github.com/HGInsights/snowpack/commit/9e5a9ba3c0d1e1725684dcd86131b4f45c5d237b))
