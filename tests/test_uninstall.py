#!/usr/bin/env python3
"""
Test suite for uninstall.sh script
"""
import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path
import pytest


# Check if running on macOS
IS_MACOS = sys.platform == "darwin"


class TestUninstallScript:
    """Test the uninstall.sh script functionality"""
    
    @pytest.fixture
    def script_path(self):
        """Get the path to the uninstall script"""
        return Path(__file__).parent.parent / "uninstall.sh"
    
    def test_help_flag(self, script_path):
        """Test that --help flag works"""
        result = subprocess.run(
            [str(script_path), "--help"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert "Usage:" in result.stdout
        assert "-y" in result.stdout
    
    def test_no_arguments(self, script_path):
        """Test that script fails gracefully with no arguments"""
        result = subprocess.run(
            [str(script_path)],
            capture_output=True,
            text=True
        )
        assert result.returncode == 1
        assert "Error: No app path provided" in result.stdout
    
    def test_invalid_app_path(self, script_path, tmp_path):
        """Test that script fails with invalid app path"""
        fake_app = tmp_path / "NonExistent.app"
        result = subprocess.run(
            [str(script_path), str(fake_app)],
            capture_output=True,
            text=True
        )
        assert result.returncode == 1
        assert "Cannot find app plist" in result.stdout
    
    def test_script_syntax(self, script_path):
        """Test that the script has valid bash syntax"""
        result = subprocess.run(
            ["bash", "-n", str(script_path)],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0, f"Syntax error: {result.stderr}"
    
    def test_y_flag_in_help(self, script_path):
        """Test that -y flag is documented in help"""
        result = subprocess.run(
            [str(script_path), "--help"],
            capture_output=True,
            text=True
        )
        assert "-y" in result.stdout
        assert "non-interactive" in result.stdout.lower() or "automatically" in result.stdout.lower()
    
    def test_script_is_executable(self, script_path):
        """Test that the script has executable permissions"""
        assert os.access(script_path, os.X_OK), "Script is not executable"
    
    def test_shebang_present(self, script_path):
        """Test that script has proper shebang"""
        with open(script_path, 'r') as f:
            first_line = f.readline()
        assert first_line.startswith("#!"), "Script missing shebang"
        assert "bash" in first_line, "Script should use bash"


# macOS-specific tests
@pytest.mark.skipif(not IS_MACOS, reason="Requires macOS")
class TestUninstallScriptMacOS:
    """Tests that require macOS to run"""
    
    @pytest.fixture
    def script_path(self):
        """Get the path to the uninstall script"""
        return Path(__file__).parent.parent / "uninstall.sh"
    
    @pytest.fixture
    def mock_app(self, tmp_path):
        """Create a mock .app bundle for testing"""
        app_path = tmp_path / "TestApp.app"
        contents_path = app_path / "Contents"
        contents_path.mkdir(parents=True)
        
        # Create Info.plist
        plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.test.testapp</string>
    <key>CFBundleName</key>
    <string>TestApp</string>
    <key>CFBundleExecutable</key>
    <string>TestApp</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
"""
        plist_path = contents_path / "Info.plist"
        plist_path.write_text(plist_content)
        
        return app_path
    
    @pytest.fixture
    def mock_app_files(self, tmp_path, mock_app):
        """Create mock application support files"""
        app_name = "TestApp"
        bundle_id = "com.test.testapp"
        
        # Get user's home directory
        home = Path.home()
        
        # Create various app-related files
        files_created = []
        
        # Library/Application Support
        app_support = home / "Library" / "Application Support" / app_name
        app_support.mkdir(parents=True, exist_ok=True)
        test_file = app_support / "test_data.txt"
        test_file.write_text("test data")
        files_created.append(test_file)
        
        # Library/Caches
        caches = home / "Library" / "Caches" / bundle_id
        caches.mkdir(parents=True, exist_ok=True)
        cache_file = caches / "cache.tmp"
        cache_file.write_text("cache")
        files_created.append(cache_file)
        
        # Library/Preferences
        prefs = home / "Library" / "Preferences"
        prefs.mkdir(parents=True, exist_ok=True)
        pref_file = prefs / f"{bundle_id}.plist"
        pref_file.write_text("preferences")
        files_created.append(pref_file)
        
        yield {
            "app": mock_app,
            "files": files_created,
        }
        
        # Cleanup
        for file in files_created:
            try:
                if file.is_file():
                    file.unlink()
                elif file.is_dir():
                    shutil.rmtree(file)
            except Exception:
                pass
    
    def test_missing_bundle_identifier(self, script_path, tmp_path):
        """Test that script fails when bundle identifier is missing"""
        app_path = tmp_path / "BadApp.app"
        contents_path = app_path / "Contents"
        contents_path.mkdir(parents=True)
        
        # Create Info.plist without CFBundleIdentifier
        plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>BadApp</string>
</dict>
</plist>
"""
        plist_path = contents_path / "Info.plist"
        plist_path.write_text(plist_content)
        
        result = subprocess.run(
            [str(script_path), str(app_path)],
            capture_output=True,
            text=True
        )
        assert result.returncode == 1
        assert "Cannot find app bundle identifier" in result.stdout
    
    def test_app_info_extraction(self, script_path, mock_app):
        """Test that app information is correctly extracted and displayed"""
        result = subprocess.run(
            [str(script_path), str(mock_app)],
            input="n\n",
            capture_output=True,
            text=True
        )
        
        assert "App Information:" in result.stdout
        assert "Name: TestApp" in result.stdout
        assert "Bundle ID: com.test.testapp" in result.stdout
        assert "Executable: TestApp" in result.stdout
    
    def test_file_discovery(self, script_path, mock_app):
        """Test that the script discovers related files"""
        result = subprocess.run(
            [str(script_path), str(mock_app)],
            input="n\n",
            capture_output=True,
            text=True
        )
        
        assert "Finding app data…" in result.stdout or "Finding app data..." in result.stdout
        assert "Searching for files matching:" in result.stdout
    
    def test_y_flag_non_interactive(self, script_path, mock_app):
        """Test that -y flag enables non-interactive mode"""
        result = subprocess.run(
            [str(script_path), "-y", str(mock_app)],
            capture_output=True,
            text=True
        )
        
        # Should show auto-confirm messages or complete without prompts
        assert "(y or n)?" not in result.stdout
        # Should complete successfully
        assert result.returncode == 0
    
    def test_search_terms_generation(self, script_path, mock_app):
        """Test that search terms are properly generated"""
        result = subprocess.run(
            [str(script_path), str(mock_app)],
            input="n\n",
            capture_output=True,
            text=True
        )
        
        assert "Searching for files matching:" in result.stdout
        # Should include the app name or bundle ID in output
        assert "TestApp" in result.stdout or "com.test.testapp" in result.stdout
    
    def test_cancellation(self, script_path, mock_app):
        """Test that user can cancel the operation"""
        result = subprocess.run(
            [str(script_path), str(mock_app)],
            input="n\n",
            capture_output=True,
            text=True
        )
        
        # Should either show "Cancelled" or complete without errors
        assert "Cancelled" in result.stdout or result.returncode == 0
    
    def test_file_removal_with_mock_files(self, script_path, mock_app_files):
        """Test that files are actually found and can be removed"""
        app = mock_app_files["app"]
        files = mock_app_files["files"]
        
        # Verify files exist before running script
        for f in files:
            assert f.exists(), f"Test file {f} should exist"
        
        # Run script with -y flag to auto-confirm
        result = subprocess.run(
            [str(script_path), "-y", str(app)],
            capture_output=True,
            text=True
        )
        
        # Should complete successfully
        assert result.returncode == 0
        
        # Files should be removed
        for f in files:
            assert not f.exists(), f"File {f} should have been removed"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
