# Changelog

## Improvements - November 2025

### Enhanced macOS Application Detection

**Fixed Issues:**
- Fixed app name extraction bug that used `$1` instead of `$app_path` when `--dry-run` was used
- Increased search depth from 1 to 2-3 levels for better detection of nested files
- Added symlink following with `-L` flag to find files referenced through symbolic links

**New Features:**
- Extract and search by multiple app identifiers:
  - App name (from .app bundle)
  - Bundle identifier (from Info.plist)
  - Executable name (CFBundleExecutable)
  - Bundle name (CFBundleName)
  - Bundle ID components (e.g., "company" and "appname" from com.company.appname)
- Added color-coded output for better readability
- Display app information before searching
- Show search terms being used for transparency
- Improved process detection using all app identifiers

**Additional Search Locations:**
- `~/Library/Cookies/` - App-specific cookies
- `~/Library/WebKit/` subdirectories - WebKit data
- `~/.config/` - Modern config directory
- `~/.local/share/` - XDG base directory
- `/Library/StartupItems/` - Legacy startup items

**Simplified User Experience:**
- Removed `--dry-run` flag (redundant since confirmation is always required)
- Replaced unreliable AppleScript trash functionality with direct `rm -rf` command
- Files are now permanently deleted instead of moved to trash
- Added batch processing with error tracking
- Improved help text and user prompts

**Performance & Reliability:**
- Better error filtering for permission denied and missing directories
- Handles command line length limits with batch processing
- More robust error handling with failure counting
- Eliminates AppleScript errors and file size limitations
