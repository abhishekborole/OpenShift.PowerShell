# Validation record — 0.1.0

On 2026-10-31, `./Build/Test.ps1` completed with **41 passed, 0 failed, 0 skipped** using Windows, PowerShell 7.4.13 and Pester 5.7.1. Python 3.14.3 hosted the loopback HTTPS fixture. The final run completed in approximately 40 seconds. Local NUnit evidence is generated in ignored `TestResults/unit.xml`.

The suite covers session and authentication policy, discovery and version caching, paginated reads, selectors, redaction, error privacy, retry behavior, read-only enforcement, WhatIf, DPAPI round-trip and pipeline session cleanup. It also starts real local child processes and an HTTPS server with a temporary private CA and client certificate. Those tests verify literal arguments, stderr, timeout, mutual TLS, bearer tokens, hostname/CA rejection, redirect blocking and GET/POST/PUT/PATCH/DELETE transport.

No actual OpenShift cluster, OAuth identity provider, installed oc binary or KubeVirt/CDI operator was available for live acceptance. Kubeconfig command behavior uses mocked oc output and a separately tested real process runner. Linux CI is configured but its result must be checked separately. No production certification or complete product-feature coverage is implied.
