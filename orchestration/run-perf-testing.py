import sys
import os
import glob
import json
import subprocess
import re
import urllib.request

# Parse the json configuration files
print("Parsing supplied config files...")
with open('orchestration/default_configs/perf-test-espresso-examples.json') as test_config_file:
    data = json.load(test_config_file)

    print("Found: %s image items in the config file for processing." % len(data))

    for test_image in data:
        # Verify that we have a device name and config type
        if not test_image["configType"]:
            print("CONFIG ERROR: Missing config type (configType), skipping image for testing.")
            continue

        if not test_image["imgType"]:
            print("CONFIG ERROR: Missing image type (imgType), skipping image for testing.")
            continue

        if not test_image["imgVersion"]:
            print("CONFIG ERROR: %s %s Missing image version (imgVersion), skipping image for testing." % (test_image["imgType"], test_image["configType"]))
            continue

        if not test_image["imgLoc"]:
            print("CONFIG ERROR: %s %s is Missing image location (imgLoc), skipping image for testing." % (test_image["imgType"], test_image["configType"]))
            continue

        if not test_image["configLocation"]:
            print("CONFIG ERROR: %s %s is Missing config location (configLocation), skipping image for testing." % (test_image["imgType"], test_image["configType"]))
            continue
        
        # Verify that all directories for configs are valid
        if not os.path.isfile(test_image["configLocation"]) and len(glob.glob(test_image["configLocation"])) == 0:
            print("CONFIG ERROR: %s %s has invalid config locations for %s, skipping." % (test_image["imgType"], test_image["configType"], test_image["configLocation"]))
            continue

        print("Locating image file from: %s" % test_image["imgLoc"])
        # If this is a folder path, we will use the image from that location
        # If this is a URL, then wget it into /tmp/ (this regex is pretty basic but not sure if we need to be super strict on it anyway)
        if re.match('^https?.*\.img\.gz', test_image["imgLoc"]) is not None:
            print("Pulling in image to /tmp ...")
            try:
                with urllib.request.urlopen(test_image["imgLoc"]) as response, open('/tmp/current.img.gz', 'wb') as out_file:
                    resp_read = response.read()
                    out_file.write(resp_read);
                    print("Finished downloading %s!" % test_image["imgLoc"])
            except:
                e = sys.exc_info()[0]
                print("Couldn't download %s because: %s" % (test_image["imgLoc"], e))
                continue
# For each json config item, deploy associated image config and call run.sh to execute the tests
print("Calling subprocess run-tests.sh script...")
subprocess.call(['run-tests.sh'], shell=True)
