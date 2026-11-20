# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.2.0] — 2026-11-20
### Added
- **kinetic**: Stat and errmsg for inputs init and read_table reject

- **gui**: A FIGURE desktop GUI, skeleton: inputs and the f0 panel

- **gui**: The solves as FIGURE tasks, and the library's thread audit

- **gui**: The Diagnostics and Transport panels

- **gui**: Scans on a task, exports, sessions and plots as PNG

- **gui**: Packages for macOS, Windows and Linux, a self-test, and their CI

- **gui**: The user guide, as a page and as the Help window


### Changed
- **electrons**: The study of a distorted f0 moves into the library


### Documentation
- Build the tests with the tests-gnu modes


### Fixed
- **ci**: Track the dependency config so ci fetches penf

- **gui**: A failed system file dialog opens FIGURE's browser

- **gui**: Link libquadmath statically on macOS; fail the package step on errors

- **gui**: Build the package README without awk -v


## [0.1.0] — 2026-11-20
### Added
- Reproduce every result of Appelbe et al. Secs. III C-VI

- **kinetic**: Accept a non-maxwellian electron f0 for ece/ts studies


### Documentation
- Add vitepress documentation with tutorial, cookbook and api

- Give the non-maxwellian electrons page its own nav entry

- Use the report's figures on the documentation site


### Fixed
- **kinetic**: Avoid heap corruption in solve_paper under nvfortran


## [0.0.1] — 2026-09-30
### Added
- Reproduce Appelbe et al. (2019) Secs. IV-VI with report


### Documentation
- Add readme and license the project under gpl v3

- **readme**: Add tag badge and link license badge to the repository


### Fixed
- **release**: Adapt the release script to this repository



