# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- CilliumNetworkPolicy was forbidding crossplane controller to download provider packages on CAPI

## [0.4.2] - 2023-01-19

### Added

- add info about crossplane providers deployed by default to CAPA and CAPZ clusters

### Fixed

- missing CiliumNetworkPolicy is now deployed as well (previously was deleted after CRD install Job succeeded)

## [0.4.1] - 2023-01-19

### Fixed

- chart now creates extra PSPs and also checks if it should create a NetworkPolicy or CiliumNetworkPolicy (fixes deploying to CAPA)

## [0.4.0] - 2023-01-12

### Changed

- crossplane upgraded to v1.10.1
- crossplane-contrib/provider-aws upgraded to v0.35.0
- crossplane version extracted to `_helper_version.tpl` to avoid changing it in 4 places
- `Secrets` access permissions are removed from the `crossplane:aggregate-to-edit` to allow for secure usage of `rbac-manager` in
Giant Swarm clusters

## [0.3.2] - 2023-01-03

### Changed

- Update path switched to git subtrees, while keeping exactly the same app version (no tag created on purpose)

## [0.3.1] - 2022-12-07

### Fixed

- Check for API capabilities before installing Custom Resources.

## [0.3.0] - 2022-11-30

### Added

- Support controller configs and enable debug logging by default for all of them.

## [0.2.1] - 2022-11-17

### Fixed

- Increase memory limit for `crd-install` Job. Previous value resulted in frequent `OOMKilled` status.

## [0.2.0] - 2022-11-15

### Added

- Add support for a fixed set of Crossplane providers ([RFC](https://github.com/giantswarm/rfc/blob/main/crossplane/README.md)). It is automatically detected which one to install based on the Management Cluster's provider kind

## [0.1.0] - 2022-11-10

### Changed

- Update `crossplane` chart to `v1.9.1`

[Unreleased]: https://github.com/giantswarm/crossplane/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/giantswarm/crossplane/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/giantswarm/crossplane/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/giantswarm/crossplane/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/giantswarm/crossplane/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/giantswarm/crossplane/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/giantswarm/crossplane/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/giantswarm/crossplane/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/giantswarm/crossplane/releases/tag/v0.1.0
