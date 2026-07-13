# Security policy

## Supported version

The latest `1.x` release receives fixes.

## Reporting a vulnerability

Please do not publish exploitable details in a public issue. Use GitHub's private vulnerability reporting feature when it is available for this repository. Include a minimal reproduction, affected version and expected impact.

This library does not perform network requests or load untrusted code by itself. Applications embedding it remain responsible for validating their own content, persistence data and callbacks.
