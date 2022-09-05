## [0.7.10](https://github.com/HGInsights/snowpack/compare/v0.7.9...v0.7.10) (2022-09-05)


### Bug Fixes

* add MERGE operation to odbc no result bug list (#48) ([6385824](https://github.com/HGInsights/snowpack/commit/63858247c8461daf623134c66368337e38364778)), closes [#48](https://github.com/HGInsights/snowpack/issues/48)


* Add section on how to run tests locally (#47) ([3d95037](https://github.com/HGInsights/snowpack/commit/3d95037048009ece42d2df5d0c7af101022735f8)), closes [#47](https://github.com/HGInsights/snowpack/issues/47)

## [0.7.9](https://github.com/HGInsights/snowpack/compare/v0.7.8...v0.7.9) (2022-08-11)


### Bug Fixes

* more aggressive retry for connection_closed and debug logging (#46) ([bc5ba3a](https://github.com/HGInsights/snowpack/commit/bc5ba3a151b5fb8cd0b28e479812178f0545306f)), closes [#46](https://github.com/HGInsights/snowpack/issues/46)

## [0.7.8](https://github.com/HGInsights/snowpack/compare/v0.7.7...v0.7.8) (2022-08-10)


### Bug Fixes

* auto retry query for connection_closed error (#45) ([209475c](https://github.com/HGInsights/snowpack/commit/209475c61a1ff0cabe2de18397e1778dd628a575)), closes [#45](https://github.com/HGInsights/snowpack/issues/45)

## [0.7.7](https://github.com/HGInsights/snowpack/compare/v0.7.6...v0.7.7) (2022-08-04)


### Bug Fixes

* signal connection to disconnect when a connection_closed error is received from ODBC (#44) ([6ba9266](https://github.com/HGInsights/snowpack/commit/6ba9266104152b50048aa2ddd7098f790b762ea2)), closes [#44](https://github.com/HGInsights/snowpack/issues/44)

## [0.7.6](https://github.com/HGInsights/snowpack/compare/v0.7.5...v0.7.6) (2022-07-21)


### Bug Fixes

* handle error response from LAST_QUERY_ID sql_query (#43) ([6d6de72](https://github.com/HGInsights/snowpack/commit/6d6de72e49a21e5d72cde49b9f7e3956eb3797e2)), closes [#43](https://github.com/HGInsights/snowpack/issues/43)

## [0.7.5](https://github.com/HGInsights/snowpack/compare/v0.7.4...v0.7.5) (2022-07-20)


### Bug Fixes

* :bug: special handling for invalid errors returned for DML statements with no results (#42) ([37fcf36](https://github.com/HGInsights/snowpack/commit/37fcf363f71c9b5b10caed54bf072f2323f03f62)), closes [#42](https://github.com/HGInsights/snowpack/issues/42) [#41](https://github.com/HGInsights/snowpack/issues/41)

## [0.7.4](https://github.com/HGInsights/snowpack/compare/v0.7.3...v0.7.4) (2022-06-28)


### Bug Fixes

* parse null float, integer, and boolean values (#40) ([78fc64c](https://github.com/HGInsights/snowpack/commit/78fc64cb1dc7b9f55d4d9fe1d2dfe384d4045172)), closes [#40](https://github.com/HGInsights/snowpack/issues/40)


### Chores

* added CODEOWERS file ([5454e60](https://github.com/HGInsights/snowpack/commit/5454e6071c4b83e516b8dd6641402afc482d2bca))

## [0.7.3](https://github.com/HGInsights/snowpack/compare/v0.7.2...v0.7.3) (2022-06-14)


### Bug Fixes

* :bug: change logging of unsupported type parsing to be debug log level (#39) ([6162d2f](https://github.com/HGInsights/snowpack/commit/6162d2fba6be7539f9968fa178ef0feaf0f808df)), closes [#39](https://github.com/HGInsights/snowpack/issues/39)

## [0.7.2](https://github.com/HGInsights/snowpack/compare/v0.7.1...v0.7.2) (2022-06-07)


### Bug Fixes

* do not try to be smart when decoding binaries without type info (#38) ([b819d43](https://github.com/HGInsights/snowpack/commit/b819d43f3fc076c717011d39f5bed45cc652c1bd)), closes [#38](https://github.com/HGInsights/snowpack/issues/38)

## [0.7.1](https://github.com/HGInsights/snowpack/compare/v0.7.0...v0.7.1) (2022-05-27)


### Bug Fixes

* parsing null time, date and datetime values (#36) ([721a48e](https://github.com/HGInsights/snowpack/commit/721a48ef1eb2cfe44f421a04bc0771a49fe4831f)), closes [#36](https://github.com/HGInsights/snowpack/issues/36)

# [0.7.0](https://github.com/HGInsights/snowpack/compare/v0.6.4...v0.7.0) (2022-05-27)


### Chores

* **docs:** update readme with badges (#34) ([88f4351](https://github.com/HGInsights/snowpack/commit/88f435155d112e5f02dc0a8feab6afe0d73f01d9)), closes [#34](https://github.com/HGInsights/snowpack/issues/34)


### Features

* added option to skip parsing of results (#35) ([4cf42ee](https://github.com/HGInsights/snowpack/commit/4cf42eec6fbf0b2603bf95eff051d21df6e76146)), closes [#35](https://github.com/HGInsights/snowpack/issues/35)

## [0.6.4](https://github.com/HGInsights/snowpack/compare/v0.6.3...v0.6.4) (2022-05-19)


### Bug Fixes

* **ci:** no v in semantic version (#33) ([5be6c84](https://github.com/HGInsights/snowpack/commit/5be6c84686c085b3dc8150d0368ee63bd27dee47)), closes [#33](https://github.com/HGInsights/snowpack/issues/33)

## [0.6.3](https://github.com/HGInsights/snowpack/compare/v0.6.2...v0.6.3) (2022-05-19)


### Bug Fixes

* **ci:** use .version file for hex packages (#32) ([0bf189d](https://github.com/HGInsights/snowpack/commit/0bf189d7bd514c6ffd6f3c884169e435f876b8e6)), closes [#32](https://github.com/HGInsights/snowpack/issues/32)

## [0.6.2](https://github.com/HGInsights/snowpack/compare/v0.6.1...v0.6.2) (2022-05-19)


### Bug Fixes

* **ci:** use semantic release outputs for version (#31) ([99c8e37](https://github.com/HGInsights/snowpack/commit/99c8e3757b4191c9d2d1f6c2494be7c813559bdd)), closes [#31](https://github.com/HGInsights/snowpack/issues/31)

## [0.6.1](https://github.com/HGInsights/snowpack/compare/v0.6.0...v0.6.1) (2022-05-19)


### Bug Fixes

* **ci:** updates for publishing to hex (#30) ([2f831f3](https://github.com/HGInsights/snowpack/commit/2f831f3760ea4a1eff4a9b8563c436856f317f72)), closes [#30](https://github.com/HGInsights/snowpack/issues/30)

# [0.6.0](https://github.com/HGInsights/snowpack/compare/v0.5.9...v0.6.0) (2022-05-17)


### Features

* added lots of tests, code clean up, docs (#28) ([dd2df43](https://github.com/HGInsights/snowpack/commit/dd2df43e3734598a47be9fbdcc730f3688f61c4c)), closes [#28](https://github.com/HGInsights/snowpack/issues/28)

## [0.5.9](https://github.com/HGInsights/snowpack/compare/v0.5.8...v0.5.9) (2022-05-05)


### Bug Fixes

* clean up docs and add tests (#23) ([a3ae744](https://github.com/HGInsights/snowpack/commit/a3ae744d1ed2093d85250f0aec261a0d3a531c8f)), closes [#23](https://github.com/HGInsights/snowpack/issues/23)


### Chores

* **ci:** update ci to test with latest Snowflake driver (#22) ([dd7577e](https://github.com/HGInsights/snowpack/commit/dd7577e2dce8b2584e4dd27e7291f73fd53d2287)), closes [#22](https://github.com/HGInsights/snowpack/issues/22)

## [0.5.8](https://github.com/HGInsights/snowpack/compare/v0.5.7...v0.5.8) (2022-04-28)


### Bug Fixes

* handle datetime and nil types and query strings with extended character sets (#21) ([873fd88](https://github.com/HGInsights/snowpack/commit/873fd888aa52a9c6ca6abafdcd9df6099ee913a6)), closes [#21](https://github.com/HGInsights/snowpack/issues/21)

## [0.5.7](https://github.com/HGInsights/snowpack/compare/v0.5.6...v0.5.7) (2022-01-26)


### Bug Fixes

* Error handling and timeouts (#20) ([6c3ada1](https://github.com/HGInsights/snowpack/commit/6c3ada1d1ddebd84ede5e5ca1c956b3bf9c18c2f)), closes [#20](https://github.com/HGInsights/snowpack/issues/20)

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
