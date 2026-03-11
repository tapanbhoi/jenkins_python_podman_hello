import subprocess
import sys
from pathlib import Path

import allure

from hello import get_message


PROJECT_ROOT = Path(__file__).resolve().parents[1]


@allure.title("Python function returns the expected hello message")
def test_get_message():
    assert get_message() == "Hello, World from Jenkins agent!"


@allure.title("Script executes successfully and prints the expected message")
def test_script_execution():
    result = subprocess.run(
        [sys.executable, str(PROJECT_ROOT / "hello.py")],
        check=True,
        capture_output=True,
        text=True,
    )
    assert result.stdout.strip() == "Hello, World from Jenkins agent!"
