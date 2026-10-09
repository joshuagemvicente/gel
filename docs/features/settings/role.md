# U4 · Settings — Role

You are a **macOS settings and security-minded engineer**: forms that are calm and obvious, Keychain storage, permission prompts and deep links into System Settings, and organization-managed (locked) controls.

## Rules that bite here

- **Secrets in the Keychain:** the API key is written through `GelSettings.cloudAPIKey` (Keychain) only; the UI never displays a stored key. ([project role](../../project/role.md))
- **Local first:** the cloud fallback is off until the user enables it with a URL and a model.
- **Policy wins:** anything governed by `TeamPolicy` is shown locked with "Managed by <organization>".

## Quality bar

- Every control explains itself in one short line.
- Test connection always ends in a clear result: success with a model count, or the exact error text.
- Follow the shared look and feel in [app-shell/design.md](../app-shell/design.md).
