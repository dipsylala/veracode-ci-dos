# SourceClear CI Script for Windows

A lightweight Windows batch script that automatically downloads, caches, and runs the SourceClear (srcclr) agent from Veracode for static code analysis.

## Overview

This script simplifies the integration of SourceClear into Windows-based CI/CD pipelines by handling:
- Automatic version detection and downloads
- Local caching to avoid repeated downloads
- Multiple extraction methods for compatibility
- Debug mode for troubleshooting

## Usage

### Basic Usage

```cmd
ci.cmd scan
```

### With Arguments

Pass any srcclr arguments directly to the script:

```cmd
ci.cmd scan --url https://github.com/example/repo
```

### Debug Mode

Enable debug output using either method:

```cmd
set DEBUG=1
ci.cmd scan
```

Or:

```cmd
ci.cmd scan --debug
```

## Features

### Version Management
- Automatically downloads the latest version from Veracode
- Supports custom version via `SRCCLR_VERSION` environment variable
- Caches downloaded versions to avoid redundant downloads

### Intelligent Caching
- Downloads are cached in `%TEMP%\srcclr\`
- Detects existing installations to skip re-downloads
- Uses unique cache directories to support concurrent executions

### Multiple Extraction Methods
The script attempts extraction using multiple methods for maximum compatibility:
1. **tar** - Built into Windows 10+
2. **PowerShell Expand-Archive** - Available on all PowerShell systems
3. **7-Zip** - Downloaded automatically as fallback

### Download Methods
Multiple download methods are tried in order:
1. **curl** - Available in Windows 10+
2. **PowerShell Invoke-WebRequest** - Fallback method

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SRCCLR_VERSION` | Specific version to download | Latest version from Veracode |
| `DEBUG` | Enable debug output | Not set (disabled) |

## Requirements

- **Windows OS**: Windows 10 or later recommended
- **PowerShell**: Required for fallback download/extraction methods
- **Network Access**: Must be able to reach `https://sca-downloads.veracode.com`

## Examples

### Specify a Version

```cmd
set SRCCLR_VERSION=3.8.50
ci.cmd scan
```

### Run with Multiple Arguments

```cmd
ci.cmd scan --json output.json --loud
```

### CI/CD Integration

```cmd
@echo off
REM In your CI pipeline script
call ci.cmd scan --url %REPO_URL%
if errorlevel 1 (
    echo SourceClear scan failed
    exit /b 1
)
```

## Cache Location

Downloaded files are stored in: `%TEMP%\srcclr\`

To clear the cache:
```cmd
rmdir /s /q "%TEMP%\srcclr"
```

## Troubleshooting

### Enable Debug Mode
```cmd
ci.cmd scan --debug
```

### Common Issues

**Error: Could not download version file**
- Check network connectivity to `https://sca-downloads.veracode.com`
- Verify proxy settings if behind a corporate firewall

**Error: srcclr not found at [path]**
- Extraction may have failed; try clearing cache and re-running
- Enable debug mode to see detailed extraction logs

**Script exits immediately**
- The script exits with code 0 if no arguments are provided
- Always provide at least one argument (e.g., `scan`)

## Notes

- This is a simplified Windows batch version of the PowerShell ci.ps1 script
- Some advanced features like true concurrent execution support are simplified
- For more robust execution, consider using the PowerShell version

## Related Files

- **ci.ps1** - PowerShell version with additional features. Download from [https://docs.veracode.com/r/Manage_agents_and_scans#set-up-an-sca-cli-agent-using-powershell](https://docs.veracode.com/r/Manage_agents_and_scans#set-up-an-sca-cli-agent-using-powershell)
