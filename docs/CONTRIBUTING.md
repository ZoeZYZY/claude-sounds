# Contributing to claude-sounds

Thanks for your interest! Here's how to contribute.

## Adding a New Theme

1. Fork the repo
2. Add URLs to `themes/MANIFEST.sh` following the existing pattern
3. Add download logic in `scripts/install.sh` and `scripts/Install-ClaudeSounds.ps1`
4. Test on your platform: `bash scripts/install.sh --theme yourtheme`
5. Open a PR with a short description of the sound style

**Sound requirements:**
- CC0 licensed only (freesound.org is a good source)
- Short clips: 0.3–2 seconds each
- 8 events: `start`, `done`, `permission`, `notify`, `write`, `bash`, `subtask`, `error`
- MP3 format preferred (broadest compatibility)

## Reporting Bugs

Please include the output of:
```bash
claude-sounds doctor
```

## Platform Testing Matrix

| Platform | Tested by |
|----------|-----------|
| macOS 14+ (Sonoma) | maintainer |
| macOS 13 (Ventura) | ? |
| Ubuntu 22.04 | ? |
| Ubuntu 24.04 | ? |
| Windows 11 | ? |
| Windows 10 | ? |
| WSL2 | ? |

If you can test on any of these, please comment in issues.
