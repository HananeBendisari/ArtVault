# Contributing to ArtVault

Thanks for your interest in contributing! Here's how to get started.

##️ Setup

1. Clone the repo  
git clone https://github.com/HananeBendisari/ArtVault.git
cd ArtVault
2. Install Foundry if not already installed
Copier
Modifier
3. Run tests
forge test --gas-report

## Pull Request Guidelines
Use clear, focused commit messages

Keep PRs atomic and minimal

Add or update tests as needed

Run forge fmt before committing

## File structure
Contracts are under contracts/

Tests are in test/

Dependencies in lib/

Build artifacts are auto-ignored via .gitignore (out/, artifacts/, cache/, etc.)

## Testing
Use Foundry (forge test)

Fuzzing and event tests encouraged!

Use forge test --gas-report before pushing

## Questions?
Open an issue or start a discussion in the repo.

