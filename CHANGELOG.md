All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.0 - Unreleased
### Added
- Support special request options for `appraisal_matrix`:
    - `versions`: An array of version restriction strings.
    - `step`: The granularity of a release to be included in the matrix. Allowed to be :major, :minor, or :patch.

## [0.1.0] - 2024-06-26
### Added
- Add an extension to the Appraisal gem that provides an interface for generating a matrix of appraisals.
