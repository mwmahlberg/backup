## [0.2.2](https://github.com/mwmahlberg/backup/compare/v0.2.1...v0.2.2) (2026-03-28)


### Features

* Add zram package to host system ([fd1d949](https://github.com/mwmahlberg/backup/commit/fd1d9496b3b150bd6ae69aeec9e008171838986c))
* **backup:** add recovery guides for fresh restores ([8215089](https://github.com/mwmahlberg/backup/commit/8215089886ba73c02ae5e2434b9808fa53e4f0c8))
* **backup:** add usb settings save and restore tasks ([f98ccb3](https://github.com/mwmahlberg/backup/commit/f98ccb3a120eca48a12d505d78210dd2a88991f6))


### Bug Fixes

* add missing skip-ci parameter ([c834566](https://github.com/mwmahlberg/backup/commit/c83456619f716e5da0de5003a66df3535146b16a))
* **ci:** Correct handling of version perfix "v" ([2ef6ada](https://github.com/mwmahlberg/backup/commit/2ef6ada7430a7e8648ebe78c22bd35eadb4accea))
* **ci:** do not skip ci when changelogs are pushed. ([77744b8](https://github.com/mwmahlberg/backup/commit/77744b834c459abb53562feb31f4e097fe7b9ff0))
* **ci:** Explicitly do not skip ci after changelog generation ([e281726](https://github.com/mwmahlberg/backup/commit/e281726216739a86f83e401d6faf1fd5a903b06f))
* **ci:** publish tagged release assets from git ([0ba4f48](https://github.com/mwmahlberg/backup/commit/0ba4f48ab74431d83ef5d03ac07ffdd3a8c054a1))
* **ci:** Use tag range to generate CHANGELOG.md ([ee945e1](https://github.com/mwmahlberg/backup/commit/ee945e113c43747cbabf47c7264e15e1156c4ba6))

## [0.1.0](https://github.com/mwmahlberg/backup/compare/v0.0.0...v0.1.0) (2026-03-16)


### Features

* add checks and pruning ([558acdd](https://github.com/mwmahlberg/backup/commit/558acdd1473d690c1310b58a2f6e9221f4f0f8cd))
* added lock wait and one-file-system ([e3aefdc](https://github.com/mwmahlberg/backup/commit/e3aefdc44dc95f1be8a00b5f3bb64bbe38a2cabc))
* **ci:** add daily Fedora 43 rebuilds for main and develop ([7eb714a](https://github.com/mwmahlberg/backup/commit/7eb714a60055a78b2d13dbc887981fca7889b2e8))
* **ci:** add git-flow release changelog and github release workflow ([541e589](https://github.com/mwmahlberg/backup/commit/541e589f8981d81eab8105a02fdfd3f07ea4dd7e))
* **ci:** add GitHub Actions build-push workflow and Dependabot config ([42545d1](https://github.com/mwmahlberg/backup/commit/42545d117b8ad07e2b7ba18dfccafd2575ddf015))
* **ci:** auto-approve and auto-merge dependabot base image updates ([63a013c](https://github.com/mwmahlberg/backup/commit/63a013c18f7454e772e31393736d41f61348a9e3))
* **ci:** derive image tags from Dockerfile Fedora major ([04ec502](https://github.com/mwmahlberg/backup/commit/04ec502a661ebf477c3cc31d180eaba66cff860b))
* **ci:** parameterize image builds and add update notification workflow ([e8d2ff3](https://github.com/mwmahlberg/backup/commit/e8d2ff35d64377ec793e523d83e563bf243d3ab0))
* **ci:** use dev image tag for develop builds ([154fc93](https://github.com/mwmahlberg/backup/commit/154fc93c068e597ceeb17046ad56a05e729161c2))
* exclude all dirs with ".resticignore",".nobackup" or ".backupignore" present ([69cbb24](https://github.com/mwmahlberg/backup/commit/69cbb24e6b3f13903156f9977da5b1fe3e18a099))
* **image:** add all bundled sources to image:build sources list ([7212196](https://github.com/mwmahlberg/backup/commit/721219686ec0a6095f289c4807a6df84f4b64a31))
* **image:** add cosign to workstation image ([1295b78](https://github.com/mwmahlberg/backup/commit/1295b78b297adcd5f0613d6e267e8db066a695f5))
* **image:** add go-task package and /usr/bin/task symlink ([7467b1b](https://github.com/mwmahlberg/backup/commit/7467b1b92563c7a7fed15ea4cad53d8139b9d732))
* **image:** add keyless signing workflow ([6677712](https://github.com/mwmahlberg/backup/commit/6677712c569712a427ac49c9c644e2c1c1863615))
* **image:** bundle backup code under /usr/share/backup ([b2cba85](https://github.com/mwmahlberg/backup/commit/b2cba85e351b2f2620b8c80741fae931a17525b8))
* **image:** update Containerfile to bundle .task/ and .taskrc.yml ([0b00ae1](https://github.com/mwmahlberg/backup/commit/0b00ae17e1b32726e1bf1e76c402e44c40f06628))
* **kinoite:** add git-flow-next ([2cba36b](https://github.com/mwmahlberg/backup/commit/2cba36badc01536d870cdd427371c5ee302f6e1d))
* **kinoite:** add OCI image labels ([643d20a](https://github.com/mwmahlberg/backup/commit/643d20a13d78274d8ebd16cb7860c0b44d68bd96))
* **restore:** add restore preflight checks and guidance ([d1babc1](https://github.com/mwmahlberg/backup/commit/d1babc1e70e3e56981d6f70d2575bb7117768eae))
* **restore:** add snapshot selection tasks ([e4d459c](https://github.com/mwmahlberg/backup/commit/e4d459c4363af3d699a8e4f2805f2ddfd2edc74e))
* **restore:** improve bootstrap progress reporting ([e3dbee6](https://github.com/mwmahlberg/backup/commit/e3dbee6e4607d65fb4d6c5d421e33fa6ef49a616))
* **restore:** replace git clone with image-bundled seed in backup-init.sh ([491fc7d](https://github.com/mwmahlberg/backup/commit/491fc7d479b6bede73bbeee31c16345ea68f5899))
* **restore:** ship backup-init helper in image ([2293d9c](https://github.com/mwmahlberg/backup/commit/2293d9ce5ae9280b96803d3fd2017b9a36caf4b9))
* **system:** add in-system auto-update channel workflow ([fbef30a](https://github.com/mwmahlberg/backup/commit/fbef30a11afe2a984fb44339541614b1a1018922))
* **taskfile:** add guided backup/restore UX tasks ([5df9096](https://github.com/mwmahlberg/backup/commit/5df90965d4961bddb01b2fab4104101c922bc872))
* **taskfile:** add task automation for build, push, rebase, login, and restore ([3546dc7](https://github.com/mwmahlberg/backup/commit/3546dc750124504ff97ee2cbc1c026da3b42aaa8))
* **taskfile:** externalize namespaced tasks and enable interactive prompting ([88f2a3c](https://github.com/mwmahlberg/backup/commit/88f2a3c750a20696eaa068028f6edb53bf87e07a)), closes [#2579](https://github.com/mwmahlberg/backup/issues/2579)


### Bug Fixes

* **ci:** normalize v-prefix handling for git-flow releases ([d9b9027](https://github.com/mwmahlberg/backup/commit/d9b90270f4750bcece767d60db17574b38e61959))
* **ci:** simplify auto-approve using GITHUB_TOKEN with review message ([d3d82b3](https://github.com/mwmahlberg/backup/commit/d3d82b3bac2ddb8c36420f2a9557953662e60a88))
* **image:** install cosign binary from upstream release ([6959c67](https://github.com/mwmahlberg/backup/commit/6959c6788307d3b05d30e63c48b30a5a115c2f21))
* **kinoite:** avoid rpmfusion base/layer conflicts on rebase ([902530e](https://github.com/mwmahlberg/backup/commit/902530e21685b4ac79b3c28ee0f1a926a09de9ad))
* **kinoite:** use stable rpmfusion keys and precreate alloy user ([e285fb4](https://github.com/mwmahlberg/backup/commit/e285fb47b0caec34c7a132eaa30a200a2ea5a7cb))
* **restic:** add schedule-jitter to prevent boot-time lock races ([9209067](https://github.com/mwmahlberg/backup/commit/9209067beeb1bd94eae06f0dc7028f9a6ba0fcc0))
* **restic:** move prevent-sleep to [global], update config path to XDG ([472d122](https://github.com/mwmahlberg/backup/commit/472d1225070215b8915bcff0b42f627f7e9be1a8))
* **restic:** set quarter-past check schedule with lock wait ([a226510](https://github.com/mwmahlberg/backup/commit/a226510c5ad07d6e131adb4a342a00c20e66ab9e))
* **restic:** use RESTIC_REPOSITORY env var instead of hardcoded URL ([5a0610b](https://github.com/mwmahlberg/backup/commit/5a0610b2fbd5167d0644c2d7761303c6c2abae49))
* **restore:** exclude restic config from backup and restore ([4e401b4](https://github.com/mwmahlberg/backup/commit/4e401b4cf1c43ab783cd2da802c7e8ab108bfbce))

## 0.0.0 (2026-03-14)

