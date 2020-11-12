import json
import subprocess

# Parse the json configuration files
print("Parsing supplied config files...")
# For each json config item, deploy associated image config and call run.sh to execute the tests
print("Calling subprocess run-tests.sh script...")
subprocess.call(['run-tests.sh'], shell=True)
