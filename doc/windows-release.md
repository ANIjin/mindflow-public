# Windows release packaging

Flutter writes the Windows release binary to:

`build/windows/x64/runner/Release/`

The GitHub Action `.github/workflows/windows-release.yml` must zip that folder
(not `build/windows/x64/release`). On a Windows runner, prefer PowerShell:

```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath mindflow-windows.zip -Force
```

If CI fails on MSVC coroutine deprecation warnings, ensure
`windows/CMakeLists.txt` defines `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`.
