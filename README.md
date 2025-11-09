# Uninstall CLI

This script is an open-source alternative for [App Cleaner](https://freemacsoft.net/appcleaner/) on Mac OS

The script is created following Sun Knudsen's [How to clean uninstall macOS apps using AppCleaner open source alternative](https://github.com/sunknudsen/privacy-guides/tree/master/how-to-clean-uninstall-macos-apps-using-appcleaner-open-source-alternative) tutorial. The repo is set up so that people can clone and contribute to make it better.

## Installation

To install, simply run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/bradflaugher/uninstall-cli/main/install.sh | bash
```

## Usage

To uninstall an application, run the `uninstall` command followed by the path to the application. For example:

```bash
uninstall /Applications/YourApp.app
```

### Dry Run

To see a list of files that will be deleted without actually deleting them, use the `--dry-run` flag:

```bash
uninstall --dry-run /Applications/YourApp.app
```

## Uninstall

To uninstall this tool, run the following command:

```bash
sudo rm /usr/local/bin/uninstall
```
