# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Upgrade `crossplane` to version `v2.4.3`. Must be upgraded from `v2.3`. Breaking changes:
  - Package revision names now include the package `metadata.generation`: on upgrade every installed `Provider`/`Function`/`Configuration` gets a new revision and provider/function pods are restarted once.
  - Package runtime objects (`Deployment`, `ServiceAccount`, `Service`, TLS `Secrets`) are applied with server-side apply; fields removed from a `DeploymentRuntimeConfig` are now removed from the live objects.
  - Safe-start capable providers are scaled to zero until one of their `ManagedResourceDefinitions` is activated (new `RuntimeActive` condition).
  - `ProviderRevision`/`FunctionRevision` printer column `RUNTIME` renamed to `RUNTIME-HEALTHY`; new `RUNTIME-ACTIVE` column.
  - The `type` label on `engine_watches_started_total`/`engine_watches_stopped_total` changed from `ComposedResource` to `Dependency`.
  - The Crossplane CLI is only published to `cli.crossplane.io` as `crossplane`.
- Upgrade `crossplane` to version `v2.3.7`. Must be upgraded from `v2.2`. Breaking changes:
  - The Crossplane CLI moved to its own repository (`crossplane/cli`) with a noun-first command tree (e.g. `crossplane beta trace` is now `crossplane resource trace`).
  - Crossplane Go APIs moved to the separate module `github.com/crossplane/crossplane/apis/v2` (affects Go consumers only).
- Upgrade `crossplane` to version `v2.2.7`. Must be upgraded from `v2.1`. Breaking changes:
  - Input CRDs shipped in `Function` packages are no longer installed by the package manager; unknown/disallowed objects in packages are ignored instead of failing installation.
  - The on-disk package cache layout changed (packages are re-fetched; side-loading packages into the cache no longer works).
  - Chart: removed the leftover external secret store wiring (`ess-server-certs` Secret); new values `secrets.customAnnotations` and `sidecarsCrossplane`; `extraVolumesCrossplane`/`extraVolumeMountsCrossplane` support template expressions.
- Upgrade `crossplane` to version `v2.1.8`. Must be upgraded from `v2.0`. Breaking changes:
  - Crossplane's custom and client-side rate limiting were removed in favour of API Priority and Fairness plus a per-XR circuit breaker. `--max-reconcile-rate` is now an alias of `--max-concurrent-reconciles` (worker pool size).
- Upgrade `crossplane` to version `v2.0.8`. This is a major upgrade; must be upgraded from `v1.20`. Breaking changes:
  - Removed `ControllerConfig` (`pkg.crossplane.io/v1alpha1`); use `DeploymentRuntimeConfig`. The CRD is no longer shipped.
  - Removed external secret stores (`--enable-external-secret-stores`, `secrets.crossplane.io` `StoreConfig` CRD) and composite resource connection details.
  - Removed native patch-and-transform compositions (`mode: Resources`); only `mode: Pipeline` is supported.
  - Removed the default registry (`--registry`): all package references must be fully qualified.
  - Metrics renamed: `crossplane_composition_controllers_*`/`crossplane_composition_watches_*` -> `engine_*`, `crossplane_composition_run_function_*` -> `function_run_function_*`.
  - New CRDs: `ManagedResourceDefinition`, `ManagedResourceActivationPolicy`, `ops.crossplane.io` `Operation`/`CronOperation`/`WatchOperation`, `protection.crossplane.io` `Usage`/`ClusterUsage`.
  - New values `provider.defaultActivations` (default `["*"]`, activates all managed resources) and `extraEnvVarsCrossplaneInit`.

## [2.6.0] - 2026-10-29

### Changed

- Upgrade `crossplane` to version `v1.20.14`.

### Fixed

- The `helm.sh/chart` label is valid for long chart versions: the 63-character cut trims the whole trailing run of `-`, `.` and `_`.

## [2.5.2] - 2026-01-08

### Changed

- Migrate Chart.yaml annotations to new format as per https://docs.giantswarm.io/reference/platform-api/chart-metadata/

## [2.5.1] - 2024-04-17

### Changed

- Upgrade `crossplane` to version `v1.15.2`

## [2.5.0] - 2024-03-28

### Changed

- Upgrade `crossplane` to version `v1.15.1`

## [2.4.3] - 2024-03-18

### Fixed

- Restrict CRD job's security context to comply with PSS.
- Change security context defaults to comply with PSS.

## [2.4.2] - 2024-01-29

### Fixed

- Move pss values under the global property

## [2.4.1] - 2023-12-20

### Changed

- Configure `gsoci.azurecr.io` as the default container image registry.

## [2.4.0] - 2023-11-02

### Changed

- Add a switch for PSP CR installation.
- Upgraded `crossplane` to version `v1.14.0`

## [2.3.0] - 2023-06-13

### Changed

- Updated `crossplane` to `v1.12.1`

## [2.2.1] - 2023-05-24

## [2.2.0] - 2023-05-09

### Added

- Added `node-role.kubernetes.io/control-plane` to crd install jobs toleration
- Updated `crossplane` to `v1.11.3`

## [2.1.0] - 2023-03-02

### Changed

- disable leader election in default values since the default replica count is 1
- add 'projected' volume to allowed ones in PSP

## [2.0.0] - 2023-02-27

### Removed

- remove support for provider management from the application chart

### Changed

- updated `crossplane` to `v1.11.0`

## [1.1.0] - 2023-02-08

### Added

- add `giantswarm.crossplane.providers.contribAws.enabled` Helm value to toggle community AWS provider, disabled by default

## [1.0.0] - 2023-02-01

### Changed

- updated `crossplane` to `v1.10.2`
- changed providers to the official `upbound` ones, for `aws` the community (`contrib`) provider is kept along as is for now to support migration
- increased default resource limits for core `crossplane` components as we observed many OOM kills and so restarts with the current official providers

### Added

- Added support for `VPA` for core crossplane components, enabled by default

## [0.4.3] - 2023-01-26

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

[Unreleased]: https://github.com/giantswarm/crossplane/compare/v2.6.0...HEAD
[2.6.0]: https://github.com/giantswarm/crossplane/compare/v2.5.2...v2.6.0
[2.5.2]: https://github.com/giantswarm/crossplane/compare/v2.5.1...v2.5.2
[2.5.1]: https://github.com/giantswarm/crossplane/compare/v2.5.0...v2.5.1
[2.5.0]: https://github.com/giantswarm/crossplane/compare/v2.4.3...v2.5.0
[2.4.3]: https://github.com/giantswarm/crossplane/compare/v2.4.2...v2.4.3
[2.4.2]: https://github.com/giantswarm/crossplane/compare/v2.4.1...v2.4.2
[2.4.1]: https://github.com/giantswarm/crossplane/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/giantswarm/crossplane/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/giantswarm/crossplane/compare/v2.2.1...v2.3.0
[2.2.1]: https://github.com/giantswarm/crossplane/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/giantswarm/crossplane/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/giantswarm/crossplane/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/giantswarm/crossplane/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/giantswarm/crossplane/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/giantswarm/crossplane/compare/v0.4.3...v1.0.0
[0.4.3]: https://github.com/giantswarm/crossplane/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/giantswarm/crossplane/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/giantswarm/crossplane/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/giantswarm/crossplane/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/giantswarm/crossplane/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/giantswarm/crossplane/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/giantswarm/crossplane/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/giantswarm/crossplane/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/giantswarm/crossplane/releases/tag/v0.1.0
