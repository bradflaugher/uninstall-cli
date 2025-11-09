# Uninstall

This script is an open-source alternative for [App Cleaner](https://freemacsoft.net/appcleaner/) on Mac OS

The script is created following Sun Knudsen's [How to clean uninstall macOS apps using AppCleaner open source alternative](https://github.com/sunknudsen/privacy-guides/tree/master/how-to-clean-uninstall-macos-apps-using-appcleaner-open-source-alternative) tutorial. The repo is set up so that people can clone and contribute to make it better.

## Installation

To install, simply run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/bradflaugher/uninstall-cli/main/install.sh | bash
```

## Usage

To uninstall an application, run the `uninstall` command followed by the path to the application:

```bash
uninstall /Applications/YourApp.app
```

The script will:
1. Display all files and folders associated with the application
2. Ask for confirmation before permanently removing them
3. Use `sudo rm -rf` to completely remove all associated files

**Note:** Files are permanently deleted, not moved to trash.

### Non-Interactive Mode

For automation or scripting, use the `-y` flag to automatically confirm all prompts:

```bash
uninstall -y /Applications/YourApp.app
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
