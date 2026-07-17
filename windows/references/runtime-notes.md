# Runtime notes

- The launcher discovers the current signed, non-development `OpenAI.Codex` Store package on every run and activates its registered application with `--remote-debugging-address=127.0.0.1`.
- Node.js 22 or newer is required. The real Node executable, version, injector path, PID and start time are recorded for cleanup identity checks.
- The preferred port is 9335. An automatic launch scans at most 100 loopback ports; an explicitly occupied port is rejected.
- CDP is accepted only when the listener PID resolves to the exact registered `ChatGPT.exe`, all WebSocket URLs are loopback and same-port, `/json/version` has a valid Browser ID, and the target exposes Codex shell markers.
- The Browser WebSocket remains open as an identity anchor. If it closes or the port is reused, the watcher exits rather than reconnecting to an unknown target.
- `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1` contains the installed, hash-verified theme package.
- `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\state.json` records the Browser ID, registered Appx identity, port, injector/Node identity and process timestamps.
- `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json` contains only the sanitized opacity and effect switches. Writes use a sibling temporary file and atomic replacement.
- The theme does not read or write Codex config.toml. It also does not modify WindowsApps, `app.asar`, API/model settings, authentication, services, scheduled tasks, Run keys or Startup folders.
- Loopback CDP is not authenticated against other processes running as the same Windows user. Use only trusted local software while the themed session is active, and restore official mode when finished.
- The managed package/runtime roots reject links and junctions before copy, removal or state writes. Artwork is capped at 16 MB, 16384 px per dimension and 50 MP.
- Only the launcher and restore shortcuts are installed. Daily launch/verify/restore uses process-scoped `RemoteSigned`; `Bypass` is reserved for the user-invoked installer.
- Restore revalidates package, process, Browser ID and recorded injector identity before stopping anything. Mismatch preserves state and fails closed.
- Complete uninstall removes the two approved shortcuts plus the managed package/runtime root; official Codex user data and login state remain untouched.

## Static scan exceptions

- `ws://example.com/...` appears only in negative CDP validation self-tests and must be rejected.
- `Install-DreamSkinBaseTheme` and `Restore-DreamSkinBaseTheme` remain inside the pinned upstream UTF-8 transaction library for audit parity, but no install/start/verify/restore entrypoint calls them.
- The verifier reads the per-user Run/RunOnce keys solely to prove `NoAutostart`; it never creates or updates a registry value.
