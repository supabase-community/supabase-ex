# Changelog

All notable changes to this project are documented in this file.

## [0.7.1](https://github.com/supabase-community/supabase-ex/compare/v0.7.0...v0.7.1) (2025-09-30)


### Bug Fixes

* fetch json_library option on compile-time ([#74](https://github.com/supabase-community/supabase-ex/issues/74)) ([0c94303](https://github.com/supabase-community/supabase-ex/commit/0c943038bb12480497b2e3e9ddc56931c066d584))


### Documentation

* fix subproject URL, typos and miscellaneous edits ([#73](https://github.com/supabase-community/supabase-ex/issues/73)) ([00088a4](https://github.com/supabase-community/supabase-ex/commit/00088a4b366bb762268fe6d5d1112f4a9506b06a))


### Miscellaneous Chores

* user-management phoenix live view example ([#47](https://github.com/supabase-community/supabase-ex/issues/47)) ([af9eec9](https://github.com/supabase-community/supabase-ex/commit/af9eec9d537fd0d2ebecb304fe9341cf4f197c9a))

## [0.7.0](https://github.com/supabase-community/supabase-ex/compare/v0.6.2...v0.7.0) (2025-07-20)


### Features

* add base config ([221c1b9](https://github.com/supabase-community/supabase-ex/commit/221c1b9fefb9f8ad11b21c6447390c42e82dc242))
* add url helpers and handle more API errors ([22b9b6a](https://github.com/supabase-community/supabase-ex/commit/22b9b6a60e01948027014e9756be7ce591ec8a29))
* build with nix ([8b053b2](https://github.com/supabase-community/supabase-ex/commit/8b053b24903dbc9b715cfc8341427fce07d0157c))
* elixir days presentation ([6947423](https://github.com/supabase-community/supabase-ex/commit/69474233ec80d19f4c19a7be512d26cf0e151bdb))
* introduce examples sample apps (readme) ([b7bfe78](https://github.com/supabase-community/supabase-ex/commit/b7bfe786a62f9a0ac1b5676ea4f1aa390116818b))
* move integrations to separate repositories ([480bf22](https://github.com/supabase-community/supabase-ex/commit/480bf22f69e917c4eced68b6447a45f90e862fab))
* prepare for refactored minor version ([867af6d](https://github.com/supabase-community/supabase-ex/commit/867af6d892192b791054eadbe802ecf894c55bdf))
* supasquad presentation nov 2023 ([ee22e9e](https://github.com/supabase-community/supabase-ex/commit/ee22e9ee0da9fde22f6cc00a3c450d6512754216))
* umbrella app ([3b8fe08](https://github.com/supabase-community/supabase-ex/commit/3b8fe0890dfa274f51549c381352aa4c224abad2))


### Bug Fixes

* allow configure json library for supabase libs ([#70](https://github.com/supabase-community/supabase-ex/issues/70)) ([e290e05](https://github.com/supabase-community/supabase-ex/commit/e290e05f7b03ebed48982fe9df69d75ef221ecb3))
* correctly merge and deduplicate headers on fetcher ([1d514da](https://github.com/supabase-community/supabase-ex/commit/1d514daaf88d56a575c3014629c5dc1c135ca384))
* credo ([624041f](https://github.com/supabase-community/supabase-ex/commit/624041fd0f376f7f9edb6e1268af29d02402e610))
* ex_doc linkings ([#58](https://github.com/supabase-community/supabase-ex/issues/58)) ([494e6c5](https://github.com/supabase-community/supabase-ex/commit/494e6c562a1217792fca82afd133708c2b7e836f))
* missing api key header on requests ([#65](https://github.com/supabase-community/supabase-ex/issues/65)) ([cd8138a](https://github.com/supabase-community/supabase-ex/commit/cd8138ae58b11816957e01eff099ba85d6b33c05))
* requests options ([#67](https://github.com/supabase-community/supabase-ex/issues/67)) ([523a225](https://github.com/supabase-community/supabase-ex/commit/523a22507f31644637e26bcc86f2fed296a5cb93))
* tests ([fa6ab1c](https://github.com/supabase-community/supabase-ex/commit/fa6ab1c1c341c89105d5b09e7b66f1ec08ad2587))


### Documentation

* Simplify readme ([#69](https://github.com/supabase-community/supabase-ex/issues/69)) ([c9d02fe](https://github.com/supabase-community/supabase-ex/commit/c9d02fe78bea06dc2db02cba7eae20ed3ff06ae9))
* update readme for version compatibility ([#64](https://github.com/supabase-community/supabase-ex/issues/64)) ([614fc39](https://github.com/supabase-community/supabase-ex/commit/614fc3982ab461ce987c6bfd9f25e9ab5e1fe8ca))


### Miscellaneous Chores

* fix gh actions cache version ([#61](https://github.com/supabase-community/supabase-ex/issues/61)) ([16b1501](https://github.com/supabase-community/supabase-ex/commit/16b15016dc64051801f793a5de6822b0c914c990))
* solve on_response unatural return ([#60](https://github.com/supabase-community/supabase-ex/issues/60)) ([2454654](https://github.com/supabase-community/supabase-ex/commit/2454654b8dc0739e6d65aa763006e4f9e76bdff8))


### Continuous Integration

* finally set up correctly ([3351c45](https://github.com/supabase-community/supabase-ex/commit/3351c458d0236534c4136dc3eea3d8d8dc56292a))

## [0.6.0] - 2025-01-10
### Added
- Enhanced HTTP handling with support for custom headers, streaming, and centralized error management.
- Improved test coverage and added dependency `mox` for mocking.
- CI/CD pipeline improvements with caching for faster builds.

### Fixed
- Resolved header merging issues and inconsistencies in JSON error handling.

### Removed
- Dropped `manage_clients` option; explicit OTP management required.

### Issues
- Fixed "[Fetcher] Extract error parsing to its own module" [#23](https://github.com/supabase-community/supabase-ex/issues/23)
- Fixed "Unable to pass `auth` key inside options to `init_client`" [#45](https://github.com/supabase-community/supabase-ex/issues/45)
- Fixed "Proposal to refactor and simplify the `Supabase.Fetcher` module" [#51](https://github.com/supabase-community/supabase-ex/issues/51)
- Fixed "Invalid Unicode error during file uploads (affets `storage-ex`)" [#52](https://github.com/supabase-community/supabase-ex/issues/52)

---

## [0.5.1] - 2024-09-21
### Added
- Improved error handling for HTTP fetch operations.
- Added optional retry policies for idempotent requests.

### Fixed
- Resolved race conditions in streaming functionality.

---

## [0.5.0] - 2024-09-21
### Added
- Support for direct file uploads to cloud storage.
- Enhanced real-time subscription management.

### Fixed
- Corrected WebSocket reconnection logic under high load.

---

## [0.4.1] - 2024-08-30
### Changed
- Performance optimizations in JSON encoding and decoding.
- Improved logging for debugging.

### Fixed
- Addressed memory leaks in connection pooling.

---

## [0.4.0] - 2024-08-30
### Added
- Introduced WebSocket monitoring tools.
- Support for encrypted token storage.

---

## [0.3.7] - 2024-05-14
### Added
- Initial implementation of streaming API for large datasets.

### Fixed
- Bug fixes in the pagination logic.

---

## [0.3.6] - 2024-04-28
### Added
- Experimental support for Ecto integration.

---

## [0.3.5] - 2024-04-21
### Fixed
- Addressed intermittent crashes when initializing connections.

---

## [0.3.4] - 2024-04-21
### Changed
- Optimized internal handling of database transactions.

---

## [0.3.3] - 2024-04-21
### Added
- Support for preflight HTTP requests.

---

## [0.3.2] - 2024-04-16
### Fixed
- Resolved issues with JSON payload validation.

---

## [0.3.1] - 2024-04-15
### Fixed
- Resolved inconsistent query results in edge cases.

---

## [0.3.0] - 2023-11-20
### Added
- Major refactor introducing modular architecture.
- Support for real-time database change notifications.

---

## [0.2.3] - 2023-10-11
### Fixed
- Patched security vulnerabilities in session handling.

---

## [0.2.2] - 2023-10-10
### Added
- Middleware support for request customization.

---

## [0.2.1] - 2023-10-10
### Fixed
- Corrected behavior for long-lived connections.

---

## [0.2.0] - 2023-10-05
### Added
- Initial implementation of role-based access control.

---

## [0.1.0] - 2023-09-18
### Added
- Initial release with core features: database access, authentication, and storage support.
