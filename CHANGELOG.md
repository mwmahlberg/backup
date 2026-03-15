# Changelog

All notable changes to this project will be documented in this file.

## [0.9.1](https://github.com/mwmahlberg/backup/releases/tag/v0.9.1) (2026-03-15)


### Features

* add `cosign` to the workstation image toolset ([00441cc](https://github.com/mwmahlberg/backup/commit/00441cc))

## [0.9.0](https://github.com/mwmahlberg/backup/releases/tag/v0.9.0) (2026-03-15)


### Features

* add daily scheduled Fedora 43 rebuilds for `main` and `develop` ([5213301](https://github.com/mwmahlberg/backup/commit/5213301))


### Chores

* sync scheduled rebuild workflow changes from `main` into `develop` ([a1b7ec9](https://github.com/mwmahlberg/backup/commit/a1b7ec9))

## [0.8.1](https://github.com/mwmahlberg/backup/releases/tag/v0.8.1) (2026-03-15)


### Features

* add in-system auto-update channel workflow with `rpm-ostree` tasks ([75456a9](https://github.com/mwmahlberg/backup/commit/75456a9))
* derive image tags from Dockerfile Fedora major and publish channel tags ([f2e63e7](https://github.com/mwmahlberg/backup/commit/f2e63e7))


### Bug Fixes

* simplify Dependabot PR auto-approval using `GITHUB_TOKEN` review message ([ea5e5a8](https://github.com/mwmahlberg/backup/commit/ea5e5a8))


### Chores

* bump GitHub Actions dependencies (`checkout`, `login-action`, `build-push-action`, `setup-buildx-action`, `github-script`) ([c7d2717](https://github.com/mwmahlberg/backup/commit/c7d2717))
* align README table formatting ([0d1d4b8](https://github.com/mwmahlberg/backup/commit/0d1d4b8))

## [0.8.0](https://github.com/mwmahlberg/backup/releases/tag/v0.8.0) (2026-03-15)


### Features

* add backup checks and pruning ([5659d2f](https://github.com/mwmahlberg/backup/commit/5659d2f))
* add lock wait and one-file-system backup behavior ([885c6b8](https://github.com/mwmahlberg/backup/commit/885c6b8))
* exclude directories containing `.resticignore`, `.nobackup`, or `.backupignore` ([764dfb7](https://github.com/mwmahlberg/backup/commit/764dfb7))
* add `git-flow-next` to the workstation image ([229a3bf](https://github.com/mwmahlberg/backup/commit/229a3bf))
* add OCI image labels ([fc4ff77](https://github.com/mwmahlberg/backup/commit/fc4ff77))
* add `go-task` to the image and provide `/usr/bin/task` ([cd04172](https://github.com/mwmahlberg/backup/commit/cd04172))
* add task automation for build, push, rebase, login, and restore workflows ([5a79535](https://github.com/mwmahlberg/backup/commit/5a79535))
* ship `backup-init` helper inside the image ([924af7a](https://github.com/mwmahlberg/backup/commit/924af7a))
* add guided backup and restore UX tasks ([b7847b5](https://github.com/mwmahlberg/backup/commit/b7847b5))
* externalize namespaced tasks and enable interactive prompting ([3ee3480](https://github.com/mwmahlberg/backup/commit/3ee3480))
* bundle backup code under `/usr/share/backup` ([f94d68c](https://github.com/mwmahlberg/backup/commit/f94d68c))
* bundle task configuration files in the image ([4356d2c](https://github.com/mwmahlberg/backup/commit/4356d2c))
* track all bundled sources for image rebuilds ([a379d88](https://github.com/mwmahlberg/backup/commit/a379d88))
* add GitHub Actions image build/push workflow and Dependabot configuration ([5bb09e9](https://github.com/mwmahlberg/backup/commit/5bb09e9))
* auto-approve and auto-merge Dependabot base image updates into `develop` ([d22dbe1](https://github.com/mwmahlberg/backup/commit/d22dbe1))
* publish `:43-dev` from `develop` and `:43` from `main` ([8250f72](https://github.com/mwmahlberg/backup/commit/8250f72))


### Bug Fixes

* exclude local restic configuration from backup and restore ([65c7927](https://github.com/mwmahlberg/backup/commit/65c7927))
* avoid RPM Fusion base/layer conflicts during rebase ([fdb2c7e](https://github.com/mwmahlberg/backup/commit/fdb2c7e))
* use stable RPM Fusion keys and precreate the Alloy user ([71b504e](https://github.com/mwmahlberg/backup/commit/71b504e))
* set quarter-past check schedule together with lock wait ([38d0991](https://github.com/mwmahlberg/backup/commit/38d0991))
* add schedule jitter to avoid boot-time lock races ([2eb10e3](https://github.com/mwmahlberg/backup/commit/2eb10e3))
* move `prevent-sleep` to `[global]` and switch to XDG config paths ([e239395](https://github.com/mwmahlberg/backup/commit/e239395))
* use `RESTIC_REPOSITORY` from the environment instead of a hardcoded URL ([c7e7300](https://github.com/mwmahlberg/backup/commit/c7e7300))
* replace `git clone` with image-bundled seeding in `backup-init.sh` ([0541aa0](https://github.com/mwmahlberg/backup/commit/0541aa0))


### Refactoring

* enable maximum compression for restic backups ([cf03dee](https://github.com/mwmahlberg/backup/commit/cf03dee))
* re-apply saved workstation state automatically via `resticprofile` `run-after` ([78c2062](https://github.com/mwmahlberg/backup/commit/78c2062))
* rename `Containerfile.kinoite` to `Dockerfile` for broader tooling compatibility ([fc4bf63](https://github.com/mwmahlberg/backup/commit/fc4bf63))


### Documentation

* expand backup and restore guides and add the DWTFYW license ([370b991](https://github.com/mwmahlberg/backup/commit/370b991))
* add Kinoite rebase and signing workflow documentation ([c06eecb](https://github.com/mwmahlberg/backup/commit/c06eecb))
* rewrite documentation in German with task-oriented workflows ([4ed01a7](https://github.com/mwmahlberg/backup/commit/4ed01a7))
* rename German docs to `*.de.md` and fix internal links ([9e92579](https://github.com/mwmahlberg/backup/commit/9e92579))
* add English translations for the README and guides ([e042ffe](https://github.com/mwmahlberg/backup/commit/e042ffe))
* simplify DE/EN guides for the bundled backup workflow ([78f4d94](https://github.com/mwmahlberg/backup/commit/78f4d94))
* update task references and task tables in the README and guides ([4d72cbb](https://github.com/mwmahlberg/backup/commit/4d72cbb))
* clarify Silverblue as a valid base for the initial rebase in the README ([4c0cdf3](https://github.com/mwmahlberg/backup/commit/4c0cdf3))
* improve README and rebase-guide accuracy for the current workflow ([29d0397](https://github.com/mwmahlberg/backup/commit/29d0397))


### Chores

* ignore `.envrc` in Git ([7c57e86](https://github.com/mwmahlberg/backup/commit/7c57e86))
* format markdown tables in project documentation ([e1e6d09](https://github.com/mwmahlberg/backup/commit/e1e6d09))
* format markdown tables in `README.md` and `README.de.md` ([4b3a673](https://github.com/mwmahlberg/backup/commit/4b3a673))