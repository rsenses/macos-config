#!/usr/bin/env python3
"""Install PCOV for supported PHP versions newly installed by mise on Linux."""

import json
import os
from pathlib import Path
import subprocess
import sys


if sys.platform == "linux":
    for tool in json.loads(os.environ["MISE_INSTALLED_TOOLS"]):
        if tool["name"] != "php" or ".".join(tool["version"].split(".")[:2]) not in {"8.3", "8.4", "8.5"}:
            continue
        bin_dir = Path(tool["install_path"]) / "bin"
        env = os.environ.copy()
        env["PATH"] = f"{bin_dir}{os.pathsep}{env.get('PATH', '')}"
        # Do not load a PCOV configuration before the extension is installed.
        env["PHPRC"] = os.devnull
        env["PHP_INI_SCAN_DIR"] = ""
        subprocess.run([str(bin_dir / "pecl"), "install", "pcov"], env=env, check=True)
