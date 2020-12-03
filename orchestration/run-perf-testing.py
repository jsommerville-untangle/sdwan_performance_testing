import sys
import os
import glob
import json
import subprocess
import re
import urllib.request
import shutil
import hashlib
import time

def getImageFile(imageLocation):
    """
    getImageFile will attempt to load the supplied string value, and return the image file
    @param string imageLocation - the image file location
    @return the open/locked file 
    """

    tmp_file = '/tmp/current.img.gz'

    # Handle HTTP URL downloads
    if re.match('^https?.*\.img\.gz', imageLocation) is not None:
        print("Pulling in image to /tmp ...")
        try:
            with urllib.request.urlopen(imageLocation) as response, open(tmp_file, 'wb') as out_file:
                resp_read = response.read()
                out_file.write(resp_read)
                out_file.close()
                print("Finished downloading %s!" % imageLocation)
                return open(tmp_file, 'rb')

        except:
            e = sys.exc_info()[0]
            print("Couldn't download %s because: %s" % (imageLocation, e))
    
    # Handle local file references
    if re.match('^\/.*?\.img\.gz$', imageLocation) is not None:
        print("Using %s as the /tmp/current image file" % imageLocation)
        shutil.copyfile(imageLocation, tmp_file)
        return open(tmp_file, 'rb')

    return None

def getFileGlobs(fileLocation):
    """
    getFileGlobs will get a glob of config files after parsing the fileLocation
    @param string fileLocation
    @return glob of files
    """
    configs = glob.glob(fileLocation)
    return configs

def uploadFile(remotePath, localFile):
    """
    uploadFile will upload given file to the path specified
    """
    fileUp = subprocess.run(["scp -i id_perf -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P $DEVICE_PORT " + localFile + " $DEVICE_USER@$DEVICE_ADDR:" + remotePath], shell=True)
    if fileUp.returncode != 0:
        return False

    return True

def uploadKeys():
    """
    uploadKeys will determine the device type and then upload the ssh keys to the appropriate location
    return: the returncode from the key upload command
    """
    # Assume remote is Untangle-E3
    remoteType = "Untangle-E3"
    # We need to determine what the current device is running because some functions after this may need to be executed differently (ie: ssh-copy-id with OpenWRT) 
    print("%s : Determining current image type on the device..." % deviceName)
    getName = subprocess.run(['sshpass -p $DEVICE_PW ssh $DEVICE_USER@$DEVICE_ADDR -p $DEVICE_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null grep NAME= /etc/os-release'], shell=True, capture_output=True, text=True)

    if "OpenWrt" in getName.stdout:
        remoteType = "OpenWRT-Espressobin"

    if remoteType is "OpenWRT-Espressobin":
            print("%s : OpenWRT image type detected, using tee to upload key..." % deviceName)
            keyUpload = subprocess.run(['sshpass -p $DEVICE_PW ssh $DEVICE_USER@$DEVICE_ADDR -p $DEVICE_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "tee -a /etc/dropbear/authorized_keys" < id_perf.pub'], shell=True)
            setKeyPerms = subprocess.run(['sshpass -p $DEVICE_PW ssh $DEVICE_USER@$DEVICE_ADDR -p $DEVICE_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null chmod 600 /etc/dropbear/authorized_keys'], shell=True)

    else:
        keyUpload = subprocess.run(['sshpass -p $DEVICE_PW ssh-copy-id -i id_perf.pub $DEVICE_USER@$DEVICE_ADDR -p $DEVICE_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'], shell=True)
    
    return keyUpload.returncode

def startUpgrade():
    """
    startUpgrade will run sysupgrade on the configured device, with the current /tmp/current.img.gz file
    """
    sysupRun = subprocess.run(["ssh -i id_perf -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $DEVICE_PORT $DEVICE_USER@$DEVICE_ADDR 'sysupgrade /tmp/current.img.gz'"], shell=True)
    print(sysupRun)

def testConnections(device, port):
    """
    testConnections will try to contact the device on the passed in port in every 5s until we get a response
    @param string device - the device to try and contact (Typically an env var)
    @param string port - the port for connectivity (typically an env var)
    """
    startTime = time.time()

    print("Trying to contact %s on %s, start time: %s" % (device, port, startTime))
    while time.time() - startTime < 300:
        time.sleep(5)
        tryNc = subprocess.run(["nc -vz "+ device + " " + port], shell=True)

        # If this is successful, we can return true since we were able to talk
        if tryNc.returncode == 0:
            print("Communication successful!")
            return True
    else:
        print("Unable to communicate with %s on port %s..." % (device, port))
        return False


# Exit out if the env values are not set, can we find a way to use the SSH key for uploading to the device?? 
deviceIp = os.environ.get('DEVICE_ADDR')
deviceUser = os.environ.get('DEVICE_USER')
devicePw = os.environ.get('DEVICE_PW')
devicePort = os.environ.get('DEVICE_PORT')
configJson = os.environ.get('ORCH_CONFIG')

if deviceIp is None or deviceUser is None or devicePort is None or configJson is None:
    print("Environment Variables are not set properly, DEVICE_ADDR=%s, DEVICE_USER=%s, DEVICE_PW=%s, DEVICE_PORT=%s and ORCH_CONFIG=%s" % (deviceIp, deviceUser, devicePw, devicePort, configJson))
    sys.exit()

# Generate keys with ssh-keygen
print("Generating keys for remote container communication...")
subprocess.run(['ssh-keygen -q -t rsa -N \'\' -f ./id_perf'], shell=True)

# Parse the json configuration files
print("Parsing supplied config files...")
with open(configJson) as test_config_file:
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

        deviceName = test_image["imgType"] + "_" + test_image["imgVersion"]

        print("%s : Locating image file from: %s" % (deviceName, test_image["imgLoc"]))
        # If this is a folder path, we will use the image from that location
        # If this is a URL, then wget it into /tmp/ (this regex is pretty basic but not sure if we need to be super strict on it anyway)
        open_file = getImageFile(test_image["imgLoc"])
        if open_file is None:
            continue
        print("%s : Currently loaded img file MD5: %s" % (deviceName, hashlib.md5(open_file.read()).hexdigest()))

        print("%s : Loading config files from: %s" % (deviceName, test_image["configLocation"]))
        current_configs = getFileGlobs(test_image["configLocation"])
        if current_configs is None:
            continue
        print("%s : Current config files: %s" %  (deviceName, current_configs))
        
        keyUpload = uploadKeys()
        if keyUpload.returncode != 0:
            print("%s ERROR: An error occurred during key upload, skipping config" % deviceName)
            continue

        print("%s : Upload image to /tmp/ on device" % deviceName)
        if not uploadFile("/tmp/", open_file.name):
            print("%s ERROR: An error occurred during image upload, skipping test configuration." % deviceName)
            continue

        print("%s : Upload configs to /etc/config on device" % deviceName)
        for config in current_configs:
            if not uploadFile("/etc/config/", config):
                print("%s ERROR: An error occurred during config upload, skipping test configuration." % deviceName)
                continue

        if "runScripts" in test_image and test_image["runScripts"]:
            print("%s : Loading script files from: %s" % (deviceName, test_image["runScripts"]))
            current_scripts = getFileGlobs(test_image["runScripts"])
            if current_scripts is None:
                print("%s : runScripts are configured but no scripts are found, skipping test, runScripts: %s" %  (deviceName, test_image["runScripts"]))
                continue

            print("%s : Current script files: %s" %  (deviceName, current_scripts))

            print("%s : Upload scripts to /etc/config/scripts" % deviceName)
            for script in current_scripts:
                if not uploadFile("/etc/config/scripts/", script):
                    print("%s ERROR: An error occurred during script upload, skipping test configuration." % deviceName)
                    continue

        print("%s : Start upgrade" % deviceName)
        startUpgrade()

        print("%s Testing connectivity to the device..." % deviceName)
        if not testConnections("$DEVICE_ADDR", "$DEVICE_PORT"):
            print("%s ERROR : Unable to communicate with the device after flashing the image, exiting..." % deviceName)
            sys.exit()

        print("%s : Testing connectivity to client..." % deviceName)
        if not testConnections("$PERF_CLIENT", "$PERF_CLIENT_PORT"):
            print("%s ERROR : Unable to communicate with the client after flashing the image, skipping configuration..." % deviceName)
            continue

        print("%s : Setting device env var..." % deviceName)
        # This sed replace will replace or insert the TEST_DEVICE environment variable, depending on what type of test we are passing in 
        # FIXME: for some reason, the .env file within the container is not passed to the contexts called when runtests runs
        setTestDevice = subprocess.run(["sed \'/^TEST_DEVICE=/{h;s/=.*/="+deviceName+"/};${x;/^$/{s//TEST_DEVICE="+deviceName+"/;H};x}\' .env"], shell=True)
        print(setTestDevice)

        # We need to update the keys since the image has been updated
        keyUpload = uploadKeys()
        if keyUpload.returncode != 0:
            print("%s ERROR: An error occurred during key upload, skipping config" % deviceName)
            continue

        # If any device scripts are configured, deploy and run them before we start the testing
        if "runScripts" in test_image and test_image["runScripts"]:
            print("%s : Running script files..." % deviceName)
        # For each json config item, deploy associated image config and call run.sh to execute the tests
        print("%s : Running test containers..." % deviceName)
        subprocess.run(["run-tests.sh "+deviceName], shell=True)


print("All tests done!")
