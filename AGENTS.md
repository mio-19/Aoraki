# Agent Guidelines

- When something is with inspiration originally from internet but original url not apparent, need to leave link in nix comment.
- Always format `.nix` files with `nixfmt` before committing.
- Do not mention or introduce any specific internal project brand names in code, commit messages, documentation, or outputs. Use neutral descriptive terminology ("NixOS for Smartwatches").
- Follow patterns of existing code and upstream AsteroidOS / Mobile NixOS architecture.
- Prefer patch files over vendoring or copy-and-modifying upstream files (e.g. from AsteroidOS). Keep recipes clean by applying patches to pristine upstream sources; however, if a file is completely newly added (does not exist upstream), use a plain file instead of a patch creating it from /dev/null.
- Ensure builds succeed with `nix-build` or `nix build` before declaring a task complete.
- When `README.md` is mentioned, it means `README.adoc`.
- Do not test hardware connected to PC unless explicitly instructed to do so.
