# macOS Uninstall Script - Issue Analysis

## Current Implementation Issues

### 1. **Limited Search Depth (`-maxdepth 1`)**
The script uses `-maxdepth 1` which only searches one level deep in each location. This misses:
- Nested application support files (e.g., `~/Library/Application Support/Company/AppName/`)
- Deep cache structures
- Subdirectories within containers

**Lines 114, 118:**
```bash
find "$location" -iname "*$app_name*" -maxdepth 1 -prune
```

### 2. **App Name Extraction Issue**
**Line 39:**
```bash
app_name=$(basename $1 .app)
```
This uses `$1` instead of `$app_path`, which could be incorrect when `--dry-run` is used.

### 3. **Case-Insensitive Search Limitations**
While `-iname` is used, the bundle identifier search may miss variations in naming conventions:
- Apps with spaces vs. no spaces
- Apps with special characters
- Company prefixes in bundle IDs

### 4. **Missing Common Locations**
The script doesn't search:
- `~/Library/Cookies/` - App-specific cookies
- `~/Library/WebKit/` subdirectories
- `~/.config/` - Some apps store config here
- `~/.local/share/` - XDG base directory
- `/Library/StartupItems/` - Legacy startup items
- `/System/Library/LaunchAgents/` and `/System/Library/LaunchDaemons/` (read-only but worth checking)

### 5. **Bundle Identifier Extraction from Nested Paths**
Some apps may have components in bundle identifier that could be searched separately:
- `com.company.appname` → could search for `company` and `appname` separately

### 6. **Symlink Handling**
The script doesn't explicitly handle symlinks, which could lead to:
- Missing files if symlinks point to app data
- Potential issues with broken symlinks

### 7. **Plist Files in Preferences**
Many apps create multiple plist files with variations:
- `com.company.appname.plist`
- `com.company.appname.helper.plist`
- `com.company.appname-Helper.plist`

The current search might miss these variations.

## Proposed Improvements

1. **Increase search depth** to at least 2-3 levels for most directories
2. **Fix app_name extraction** to use `$app_path` consistently
3. **Add more search locations** for modern macOS apps
4. **Extract and search bundle ID components** separately
5. **Add symlink following** with `-L` flag where appropriate
6. **Improve pattern matching** to catch more variations
7. **Add support for searching by executable name** from Info.plist
8. **Better error handling** and user feedback
