#! /bin/bash

function main() {
  app_path=""
  auto_confirm=false
  search_mode="normal"
  exclude_patterns=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help)
        printf "%s\n" "Usage: uninstall.sh [-y] [--mode MODE] [--exclude PATTERN] /path/to/app.app"
        printf "\n"
        printf "%s\n" "This script will find and display all files associated with the app,"
        printf "%s\n" "then ask for confirmation before permanently removing them."
        printf "\n"
        printf "%s\n" "Options:"
        printf "%s\n" "  -y                Automatically confirm all prompts (non-interactive mode)"
        printf "%s\n" "  --mode MODE       Search aggressiveness: strict, normal (default), or aggressive"
        printf "%s\n" "                      strict:     Only exact bundle ID (safest)"
        printf "%s\n" "                      normal:     Bundle ID + app/executable names (no company names)"
        printf "%s\n" "                      aggressive: Includes bundle components like company names"
        printf "%s\n" "  --exclude PATTERN Exclude files matching pattern (can be used multiple times)"
        printf "%s\n" "                      Example: --exclude teams --exclude excel"
        exit 0
        ;;
      -y)
        auto_confirm=true
        shift
        ;;
      --mode)
        search_mode="$2"
        if [[ ! "$search_mode" =~ ^(strict|normal|aggressive)$ ]]; then
          printf "%s\n" "Error: Invalid mode '$search_mode'. Must be: strict, normal, or aggressive"
          exit 1
        fi
        shift 2
        ;;
      --exclude)
        exclude_patterns+=("$2")
        shift 2
        ;;
      *)
        app_path="$1"
        shift
        ;;
    esac
  done

  if [ -z "$app_path" ]; then
    printf "%s\n" "Error: No app path provided"
    printf "%s\n" "Usage: uninstall.sh [-y] [--mode MODE] [--exclude PATTERN] /path/to/app.app"
    exit 1
  fi

  IFS=$'\n'

  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  normal=$(tput sgr0)

  if [ ! -e "$app_path/Contents/Info.plist" ]; then
    printf "%s\n" "Cannot find app plist at: $app_path/Contents/Info.plist"
    exit 1
  fi

  # Extract bundle identifier
  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Contents/Info.plist" 2> /dev/null)

  if [ "$bundle_identifier" = "" ]; then
    printf "%s\n" "Cannot find app bundle identifier"
    exit 1
  fi

  # Extract app name from path
  app_name=$(basename "$app_path" .app)

  # Extract executable name from Info.plist (may differ from app name)
  executable_name=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable" "$app_path/Contents/Info.plist" 2> /dev/null)
  
  # Extract bundle name (may also differ)
  bundle_name=$(/usr/libexec/PlistBuddy -c "Print CFBundleName" "$app_path/Contents/Info.plist" 2> /dev/null)

  printf "${green}%s${normal}\n" "App Information:"
  printf "  Name: %s\n" "$app_name"
  printf "  Bundle ID: %s\n" "$bundle_identifier"
  [ -n "$executable_name" ] && printf "  Executable: %s\n" "$executable_name"
  [ -n "$bundle_name" ] && printf "  Bundle Name: %s\n" "$bundle_name"
  printf "  Search Mode: ${yellow}%s${normal}\n" "$search_mode"
  [ ${#exclude_patterns[@]} -gt 0 ] && printf "  Excluding: %s\n" "${exclude_patterns[*]}"
  printf "\n"

  # Extract bundle ID components for additional searching
  # e.g., com.company.appname -> search for "company" and "appname"
  bundle_components=($(echo "$bundle_identifier" | tr '.' '\n' | tail -n 2))

  printf "%s\n" "Checking for running processes…"
  sleep 1

  # Search for processes using app name, executable name, and bundle name
  search_terms=("$app_name")
  [ -n "$executable_name" ] && [ "$executable_name" != "$app_name" ] && search_terms+=("$executable_name")
  [ -n "$bundle_name" ] && [ "$bundle_name" != "$app_name" ] && search_terms+=("$bundle_name")

  processes=()
  for term in "${search_terms[@]}"; do
    processes+=($(pgrep -afil "$term" | grep -v "$$" | grep -v "uninstall" | grep -v "grep"))
  done

  # Remove duplicates
  processes=($(printf "%s\n" "${processes[@]}" | sort -u))

  if [ ${#processes[@]} -gt 0 ]; then
    printf "%s\n" "${processes[@]}"
    
    if [ "$auto_confirm" = true ]; then
      answer="y"
      printf "${yellow}%s${normal}\n" "Auto-confirming: killing running processes"
    else
      printf "$red%s$normal" "Kill running processes (y or n)? "
      read -r answer
    fi
    
    if [ "$answer" = "y" ]; then
      printf "%s\n" "Killing running processes…"
      sleep 1
      for process in "${processes[@]}"; do
        echo "$process" | awk '{print $1}' | xargs sudo kill 2>&1 | grep -v "No such process"
      done
    fi
  fi

  # Save bill of materials if they exist
  bom_paths=()
  bom_paths+=($(find /private/var/db/receipts -iname "*$app_name*.bom" -maxdepth 1 -prune 2>&1 | grep -v "Permission denied"))
  bom_paths+=($(find /private/var/db/receipts -iname "*$bundle_identifier*.bom" -maxdepth 1 -prune 2>&1 | grep -v "Permission denied"))

  if [ ${#bom_paths[@]} -gt 0 ]; then
    printf "%s\n" "Saving bill of material logs to desktop…"
    sleep 1
    for path in "${bom_paths[@]}"; do
      mkdir -p "$HOME/Desktop/$app_name"
      lsbom -f -l -s -p f "$path" > "$HOME/Desktop/$app_name/$(basename "$path").log"
    done
  fi

  printf "%s\n" "Finding app data…"
  sleep 1

  # Define locations with appropriate search depths
  # Format: "path:depth"
  locations=(
    "$HOME/Library:2"
    "$HOME/Library/Application Scripts:1"
    "$HOME/Library/Application Support:3"
    "$HOME/Library/Application Support/CrashReporter:2"
    "$HOME/Library/Containers:2"
    "$HOME/Library/Group Containers:2"
    "$HOME/Library/Caches:3"
    "$HOME/Library/HTTPStorages:2"
    "$HOME/Library/Cookies:2"
    "$HOME/Library/WebKit:2"
    "$HOME/Library/Internet Plug-Ins:2"
    "$HOME/Library/LaunchAgents:1"
    "$HOME/Library/Logs:3"
    "$HOME/Library/Preferences:1"
    "$HOME/Library/Preferences/ByHost:1"
    "$HOME/Library/Saved Application State:1"
    "$HOME/.config:2"
    "$HOME/.local/share:2"
    "/Library:2"
    "/Library/Application Support:3"
    "/Library/Application Support/CrashReporter:2"
    "/Library/Caches:2"
    "/Library/Extensions:2"
    "/Library/Internet Plug-Ins:2"
    "/Library/LaunchAgents:1"
    "/Library/LaunchDaemons:1"
    "/Library/Logs:2"
    "/Library/Preferences:1"
    "/Library/PrivilegedHelperTools:1"
    "/Library/StartupItems:1"
    "/private/var/db/receipts:1"
    "/usr/local/bin:1"
    "/usr/local/etc:2"
    "/usr/local/opt:2"
    "/usr/local/sbin:1"
    "/usr/local/share:2"
    "/usr/local/var:2"
    "$(getconf DARWIN_USER_CACHE_DIR | sed "s/\/$//"):2"
    "$(getconf DARWIN_USER_TEMP_DIR | sed "s/\/$//"):2"
  )

  # Start with the app itself
  paths=("$app_path")

  # Build search terms array based on mode
  search_terms=()

  case "$search_mode" in
    strict)
      # Only exact bundle ID - safest option
      search_terms=("$bundle_identifier")
      ;;
    normal)
      # Bundle ID + app/executable/bundle names, but NO company names
      search_terms=("$app_name" "$bundle_identifier")
      [ -n "$executable_name" ] && [ "$executable_name" != "$app_name" ] && search_terms+=("$executable_name")
      [ -n "$bundle_name" ] && [ "$bundle_name" != "$app_name" ] && search_terms+=("$bundle_name")
      ;;
    aggressive)
      # Everything including bundle components (company names, etc.)
      search_terms=("$app_name" "$bundle_identifier")
      [ -n "$executable_name" ] && [ "$executable_name" != "$app_name" ] && search_terms+=("$executable_name")
      [ -n "$bundle_name" ] && [ "$bundle_name" != "$app_name" ] && search_terms+=("$bundle_name")

      # Add bundle ID components if they're meaningful (more than 3 chars)
      for component in "${bundle_components[@]}"; do
        if [ ${#component} -gt 3 ]; then
          search_terms+=("$component")
        fi
      done
      ;;
  esac

  # Remove duplicates from search terms
  search_terms=($(printf "%s\n" "${search_terms[@]}" | sort -u))

  printf "${yellow}%s${normal}\n" "Searching for files matching:"
  printf "  %s\n" "${search_terms[@]}"
  printf "\n"

  # Search each location with appropriate depth
  for location_spec in "${locations[@]}"; do
    location="${location_spec%:*}"
    depth="${location_spec#*:}"

    # Skip if location doesn't exist
    [ ! -d "$location" ] && continue

    for term in "${search_terms[@]}"; do
      # Use -L to follow symlinks, and appropriate maxdepth
      found_paths=($(find -L "$location" -iname "*$term*" -maxdepth "$depth" 2>&1 | \
        grep -v "No such file or directory" | \
        grep -v "Operation not permitted" | \
        grep -v "Permission denied" | \
        grep -v "Too many levels of symbolic links"))

      paths+=("${found_paths[@]}")
    done
  done

  # Remove duplicates and sort
  paths=($(printf "%s\n" "${paths[@]}" | sort -u))

  # Apply exclude patterns if any
  if [ ${#exclude_patterns[@]} -gt 0 ]; then
    filtered_paths=()
    for path in "${paths[@]}"; do
      excluded=false
      for pattern in "${exclude_patterns[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
          excluded=true
          break
        fi
      done
      [ "$excluded" = false ] && filtered_paths+=("$path")
    done

    excluded_count=$((${#paths[@]} - ${#filtered_paths[@]}))
    paths=("${filtered_paths[@]}")

    if [ $excluded_count -gt 0 ]; then
      printf "${yellow}%s${normal}\n" "Excluded $excluded_count items matching exclude patterns"
    fi
  fi

  if [ ${#paths[@]} -eq 0 ]; then
    printf "${yellow}%s${normal}\n" "No files found to remove."
    exit 0
  fi

  printf "${green}%s${normal}\n" "Found ${#paths[@]} items:"

  # Group and display by search term
  # For bash 3.2 compatibility, we match paths against terms using pattern matching
  for term in "${search_terms[@]}"; do
    term_paths=()
    for path in "${paths[@]}"; do
      # Case-insensitive match using lowercase comparison
      path_lower=$(echo "$path" | tr '[:upper:]' '[:lower:]')
      term_lower=$(echo "$term" | tr '[:upper:]' '[:lower:]')
      if [[ "$path_lower" == *"$term_lower"* ]]; then
        term_paths+=("$path")
      fi
    done

    if [ ${#term_paths[@]} -gt 0 ]; then
      printf "\n${yellow}Matched by '%s' (${#term_paths[@]} items):${normal}\n" "$term"
      printf "%s\n" "${term_paths[@]}"
    fi
  done

  printf "\n"

  # Interactive mode: allow user to adjust search before deletion
  if [ "$auto_confirm" = false ]; then
    while true; do
      printf "${yellow}%s${normal}\n" "Options:"
      printf "  ${green}y${normal} - Proceed with deletion\n"

      # Show search mode adjustment options
      if [ "$search_mode" != "strict" ]; then
        printf "  ${green}s${normal} - Switch to stricter search (fewer items)\n"
      fi
      if [ "$search_mode" != "aggressive" ]; then
        printf "  ${green}a${normal} - Switch to more aggressive search (more items)\n"
      fi

      printf "  ${green}e${normal} - Add exclude pattern\n"
      printf "  ${green}n${normal} - Cancel\n"
      printf "\n"
      printf "$red%s$normal" "Choose an option: "
      read -r answer

      case "$answer" in
        y)
          # Proceed with deletion
          break
          ;;
        s)
          if [ "$search_mode" = "aggressive" ]; then
            search_mode="normal"
          elif [ "$search_mode" = "normal" ]; then
            search_mode="strict"
          fi

          # Re-run the search with new mode
          printf "\n${yellow}%s${normal}\n" "Switching to $search_mode mode and re-searching..."
          exec "$0" "--mode" "$search_mode" "${exclude_patterns[@]/#/--exclude}" "$app_path"
          ;;
        a)
          if [ "$search_mode" = "strict" ]; then
            search_mode="normal"
          elif [ "$search_mode" = "normal" ]; then
            search_mode="aggressive"
          fi

          # Re-run the search with new mode
          printf "\n${yellow}%s${normal}\n" "Switching to $search_mode mode and re-searching..."
          exec "$0" "--mode" "$search_mode" "${exclude_patterns[@]/#/--exclude}" "$app_path"
          ;;
        e)
          printf "%s" "Enter pattern to exclude: "
          read -r exclude_pattern
          exclude_patterns+=("$exclude_pattern")

          # Re-run the search with new exclude pattern
          printf "\n${yellow}%s${normal}\n" "Re-searching with exclude pattern '$exclude_pattern'..."
          exec "$0" "--mode" "$search_mode" "${exclude_patterns[@]/#/--exclude}" "$app_path"
          ;;
        n)
          printf "%s\n" "Cancelled."
          exit 0
          ;;
        *)
          printf "${red}%s${normal}\n" "Invalid option. Please choose y, s, a, e, or n."
          printf "\n"
          ;;
      esac
    done
  fi

  if [ "$auto_confirm" = true ] || [ "$answer" = "y" ]; then
    if [ "$auto_confirm" = true ]; then
      printf "${yellow}%s${normal}\n" "Auto-confirming: deleting ${#paths[@]} items"
    fi
    printf "%s\n" "Removing files…"
    sleep 1
    
    failed=0
    for path in "${paths[@]}"; do
      if [ -e "$path" ]; then
        sudo rm -rf "$path" 2>&1 || ((failed++))
      fi
    done
    
    if [ $failed -eq 0 ]; then
      printf "${green}%s${normal}\n" "Done! Successfully removed ${#paths[@]} items."
    else
      printf "${yellow}%s${normal}\n" "Done! Removed most items, but $failed items failed (may require additional permissions)."
    fi
  fi
}

main "$@"
