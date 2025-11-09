# Uninstall

This script is an open-source alternative for [App Cleaner](https://freemacsoft.net/appcleaner/) on Mac OS

The script is created following Sun Knudsen's [How to clean uninstall macOS apps using AppCleaner open source alternative](https://github.com/sunknudsen/guides/tree/main/archive/how-to-clean-uninstall-macos-apps-using-appcleaner-open-source-alternative) tutorial. The repo is set up so that people can clone and contribute to make it better.

## Demo

Watch this video to see the uninstall script in action:

<div style="position: relative; padding-bottom: 56.25%; height: 0;">
  <iframe src="https://www.loom.com/embed/f00d1578803b463fa887c88a4bacbfd1" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

## Installation

To install, simply run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/bradflaugher/uninstall-cli/main/install.sh | bash
```

## Usage

### Basic Usage

To uninstall an application, run the `uninstall` command followed by the path to the application:

```bash
uninstall /Applications/YourApp.app
```

The script will:
1. Extract app information (name, bundle ID, etc.)
2. Search for all related files and folders
3. Display results grouped by search term
4. Provide interactive options to refine the search
5. Ask for confirmation before permanently removing files
6. Use `sudo rm -rf` to completely remove all associated files

**Note:** Files are permanently deleted, not moved to trash.

### Interactive Mode

After viewing the search results, you'll see these options:

- **y** - Proceed with deletion
- **s** - Switch to stricter search (fewer items)
- **a** - Switch to more aggressive search (more items)
- **e** - Add exclude pattern to filter out unwanted matches
- **n** - Cancel

This allows you to refine the search until you're satisfied with the results.

**Example workflow:**
```bash
$ uninstall /Applications/OneDrive.app

# See results including Microsoft Teams, Excel, etc.
# Choose 's' to switch to strict mode
# Now only OneDrive-specific files are shown
# Choose 'y' to proceed with deletion
```

### Search Modes

Control how aggressively the script searches for related files using the `--mode` flag:

#### Strict Mode (Safest)
Only searches for exact bundle ID matches:
```bash
uninstall --mode strict /Applications/OneDrive.app
```
Searches for: `com.microsoft.OneDrive-mac` only

#### Normal Mode (Default)
Searches for bundle ID and app names, but excludes company names:
```bash
uninstall --mode normal /Applications/OneDrive.app
# or simply:
uninstall /Applications/OneDrive.app
```
Searches for: `OneDrive`, `com.microsoft.OneDrive-mac`, `OneDrive-mac`

**Won't match:** `microsoft` (prevents catching Teams, Excel, etc.)

#### Aggressive Mode
Includes bundle ID components like company names:
```bash
uninstall --mode aggressive /Applications/OneDrive.app
```
Searches for: `OneDrive`, `microsoft`, `OneDrive-mac`, `com.microsoft.OneDrive-mac`

**Warning:** May catch related applications from the same company

### Exclude Patterns

Filter out specific matches using the `--exclude` flag (can be used multiple times):

```bash
# Exclude Teams and Excel files
uninstall --exclude teams --exclude excel /Applications/OneDrive.app

# Exclude any path containing "word"
uninstall --exclude word /Applications/Office.app
```

### Non-Interactive Mode

For automation or scripting, use the `-y` flag to automatically confirm all prompts:

```bash
uninstall -y /Applications/YourApp.app

# Combine with other flags
uninstall -y --mode strict /Applications/YourApp.app
uninstall -y --exclude pattern1 --exclude pattern2 /Applications/YourApp.app
```

### Common Examples

```bash
# Safe uninstall - only exact bundle ID matches
uninstall --mode strict /Applications/Slack.app

# Default uninstall - balanced approach
uninstall /Applications/Discord.app

# Aggressive uninstall - find everything related
uninstall --mode aggressive /Applications/Adobe.app

# Exclude specific patterns
uninstall --exclude creative-cloud /Applications/Photoshop.app

# Non-interactive strict mode
uninstall -y --mode strict /Applications/TestApp.app
```

## Uninstall

To uninstall this tool, run the following command:

```bash
sudo rm /usr/local/bin/uninstall
```

## Development

### Running Tests

This project includes a test suite using pytest. To run the tests:

```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run tests
pytest tests/ -v
```

**Note:** Full integration tests require macOS as they test macOS-specific functionality like plist parsing and file discovery.

### Continuous Integration

The project uses GitHub Actions to automatically run tests on every commit. The CI pipeline runs on macOS to ensure full compatibility testing.
