# Agent Guidelines

- When something is with inspiration originally from internet but original url not apparent, need to leave link in nix comment.
- Always format `.nix` files with `nixfmt` before committing.
- Do not mention or introduce any specific internal project brand names in code, commit messages, documentation, or outputs. Use neutral descriptive terminology ("NixOS for Smartwatches").
- Follow patterns of existing code and upstream AsteroidOS / Mobile NixOS architecture.
- Ensure builds succeed with `nix-build` or `nix build` before declaring a task complete.
