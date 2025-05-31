# Security Policy

## Overview

ArtVault is an experimental smart contract protocol for milestone-based escrow payments. While the codebase is extensively tested and modular, it has not yet undergone a formal third-party audit.

## Recent Security Improvements

The protocol has recently undergone multiple internal security hardening steps:

### 1. ETH Transfer Safety (`fix/security-1`)
- Replaced all `transfer()` calls with low-level `call{value}()` and proper success checks
- Improved robustness of artist payment flows
- Affected modules: `FallbackModule`

### 2. Payment Validation
- Enforced divisibility check on `amount % milestoneCount` to avoid leftover wei
- Affected modules: `EscrowContract`, `BaseContract`

### 3. Emergency Pause (`fix/security-2`)
- Added `pause()` / `unpause()` mechanism
- Applied `whenNotPaused` modifier to critical functions
- Affected modules: `ArtVault`

### 4. Access Control & Timing Guards
- Restored `onlyClient`, `onlyValidator` modifiers where missing
- Introduced safety margin to fallback delays
- Fixed inheritance and visibility issues
- Affected modules: all core modules and test vaults

## Testing and Verification

- Full test suite executed using Foundry (`forge test --via-ir`)
- Over 50 unit and fuzz tests
- 100% pass rate across all test files
- Edge cases covered: timestamp drift, invalid milestone configs, call reverts

## Responsible Disclosure

If you discover a vulnerability or potential issue:

- Email: HananeNec@proton.me  

Please do not submit public GitHub issues related to security. Contact privately to allow time for patching.

## Disclaimer

This protocol is experimental and should not be used with real funds until a professional audit has been completed. It is intended for research, testing, and educational use only.
