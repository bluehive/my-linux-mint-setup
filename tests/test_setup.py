"""Run setup with disposable HOME and mocked system/package/network commands."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def run_setup(self, target):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            home = base / 'home'
            bin_dir = base / 'bin'
            bin_dir.mkdir()
            home.mkdir()
            local_bin = home / '.local/bin'
            local_bin.mkdir(parents=True)
            script_dir = base / 'repo'
            script_dir.mkdir()
            (script_dir / 'setup.sh').write_bytes((ROOT / 'setup.sh').read_bytes())
            (script_dir / 'config').mkdir()
            (script_dir / 'config/mise.toml').write_text('[tools]\n')
            log = base / 'commands'
            stub = '#!/bin/bash\nprintf "%s\\n" "$(basename "$0") $*" >> "$COMMAND_LOG"\n'
            for command in ('sudo', 'git', 'gh', 'im-config', 'microsoft-edge'):
                path = bin_dir / command
                path.write_text(stub)
                path.chmod(0o755)
            (bin_dir / 'id').write_text('#!/bin/bash\necho 1000\n')
            (bin_dir / 'id').chmod(0o755)
            # A fresh non-interactive shell cannot see this without the PATH fix.
            (local_bin / 'mise').write_text(stub)
            (local_bin / 'mise').chmod(0o755)
            env = dict(os.environ, HOME=str(home), PATH=f'{bin_dir}:/usr/bin:/bin', COMMAND_LOG=str(log))
            for _ in range(2):
                result = subprocess.run(['bash', str(script_dir / 'setup.sh'), target], env=env,
                                        text=True, capture_output=True, cwd='/tmp')
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual((home / '.bashrc').read_text().count('mise activate bash'), 1)
            self.assertTrue((home / '.config/mise/config.toml').exists())
            commands = log.read_text()
            self.assertIn('mise install', commands)
            return commands

    def test_wsl_skips_desktop_packages(self):
        commands = self.run_setup('wsl2')
        self.assertIn('install -y emacs-nox', commands)
        for desktop in ('firefox', 'libreoffice', 'ibus-mozc', 'microsoft-edge-stable'):
            self.assertNotIn(desktop, commands)

    def test_mint_keeps_desktop_and_uses_ibus(self):
        commands = self.run_setup('mint')
        self.assertIn('firefox-locale-ja', commands)
        self.assertIn('im-config -n ibus', commands)
        self.assertNotIn('hunspell-ja', commands)
        self.assertNotIn('emacs-nox', commands)


if __name__ == '__main__':
    unittest.main()
