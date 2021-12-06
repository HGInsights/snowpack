## [0.5.6](https://github.com/HGInsights/snowpack/compare/v0.5.5...v0.5.6) (2021-12-06)


### Bug Fixes

* change array type to :array, handle null arrays and json ([1dea4ed](https://github.com/HGInsights/snowpack/commit/1dea4ed38ef5ab53f7a24e53e7f8d7830fc640d2))


### Chores

* update Semantic Release CI step to use common config ([dc189a6](https://github.com/HGInsights/snowpack/commit/dc189a6bbb3792d7b97396c73a9bd70bd18ccbbe))

## [0.5.5](https://github.com/HGInsights/snowpack/compare/v0.5.4...v0.5.5) (2021-11-18)


### Bug Fixes

* Make ODBC GenServer query calls default timeout Infinity (#17) ([e63b4e5](https://github.com/HGInsights/snowpack/commit/e63b4e5e59abc29e6712a79ff3d2cb4f496a9775)), closes [#17](https://github.com/HGInsights/snowpack/issues/17)

## [0.5.4](https://github.com/HGInsights/snowpack/compare/v0.5.3...v0.5.4) (2021-10-29)


### Bug Fixes

* remove end_time from telemetry measurements ([92250f4](https://github.com/HGInsights/snowpack/commit/92250f4da4cb3a932d2843b55937c6a9561d5e3f))
* telemetry tests ([cb79304](https://github.com/HGInsights/snowpack/commit/cb793045bdb1be707f9534c6365dad609777f849))

## [0.5.3](https://github.com/HGInsights/snowpack/compare/v0.5.2...v0.5.3) (2021-10-29)


### Bug Fixes

* bump version and update readme ([9d93316](https://github.com/HGInsights/snowpack/commit/9d9331694a81243a6e1d3bce145d90ebb315e11b))


### Chores

* jason should be an explicit dep ([a77b1ba](https://github.com/HGInsights/snowpack/commit/a77b1bac4d486aa8ebe0c2a17b7e85dab667e7e6))

## [0.5.2](https://github.com/HGInsights/snowpack/compare/v0.5.1...v0.5.2) (2021-10-20)


### Bug Fixes

* need to supervise the cache (#16) ([3a461e3](https://github.com/HGInsights/snowpack/commit/3a461e320aec103e52176642f4ae962d7bdcc6b0)), closes [#16](https://github.com/HGInsights/snowpack/issues/16)

## [0.5.1](https://github.com/HGInsights/snowpack/compare/v0.5.0...v0.5.1) (2021-10-19)


### Bug Fixes

* remove event_prefix as it adds complication for common handlers and no real value (#15) ([a34c6b0](https://github.com/HGInsights/snowpack/commit/a34c6b09f00fc156bad1470b10842a4da20af2e6)), closes [#15](https://github.com/HGInsights/snowpack/issues/15)

# [0.5.0](https://github.com/HGInsights/snowpack/compare/v0.4.0...v0.5.0) (2021-10-18)


### Features

* add sending telemetry events for query start, stop, and exception (#14) ([42c1b7d](https://github.com/HGInsights/snowpack/commit/42c1b7de2286162ffda0ab2e781c8f4a7384aea5)), closes [#14](https://github.com/HGInsights/snowpack/issues/14)

# [0.4.0](https://github.com/HGInsights/snowpack/compare/v0.3.0...v0.4.0) (2021-10-15)


### Features

* better caching of query column types to reduce usage of transactions, LAST_QUERY_ID(), and DESCRIBE RESULT (#13) ([aba7732](https://github.com/HGInsights/snowpack/commit/aba77323488c72398347055bbeaec639236b3d05)), closes [#13](https://github.com/HGInsights/snowpack/issues/13)

# [0.3.0](https://github.com/HGInsights/snowpack/compare/v0.2.0...v0.3.0) (2021-08-20)


### Features

* Handle results from a non select statement (#12) ([a5b6f11](https://github.com/HGInsights/snowpack/commit/a5b6f11859f41dcc6d458c0ddefd43be485c1b12)), closes [#12](https://github.com/HGInsights/snowpack/issues/12)

# [0.2.0](https://github.com/HGInsights/snowpack/compare/v0.1.4...v0.2.0) (2021-05-11)


### Features

* Update type parsing to cover more types and be based on query result (fixes #5) ([8cf6b85](https://github.com/HGInsights/snowpack/commit/8cf6b85a7b3855bb8d56cd78aa85f6503aa23f4b)), closes [#5](https://github.com/HGInsights/snowpack/issues/5)

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
