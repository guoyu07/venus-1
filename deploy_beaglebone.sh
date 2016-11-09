# this script is meant to be called from the build dir, straight from bitbake.

set -e

if [ $# -eq 0 ]; then
	echo "Usage: $0 192.168.21.12   (and replace that ip address with the ip address of your beagle)"
	exit 1
fi

# On the beaglebone, /scratch is an empty partition with lots of space
echo "* Creating a fresh /scratch/swu-tmp on the remote..."
ssh root@$1 'rm -r /scratch/swu-tmp; mkdir /scratch/swu-tmp'

echo "* Uploading the latest beaglebone build..."
scp ../deploy/venus/images/beaglebone/venus-swu-beaglebone.swu root@$1:/scratch/swu-tmp/

# rsync is nice, but there is no real advantage since diffing compressed files is
# pointless.
# rsync -Lvz ../deploy/venus/images/beaglebone/venus-swu-beaglebone.swu root@$1:/scratch/swu-tmp/

echo "* Starting the update..."
# offline update scans the /media folder for usb and other media: first symlink and then run it
ssh root@$1 'ln -sf /scratch/swu-tmp /media/scratch-swu-tmp && /opt/victronenergy/swupdate-scripts/check-updates.sh -offline -force -update'

echo "* As you'll probably want to login with ssh, lets do that:"

retries=0
repeat=true
today=$(date)

while "$repeat"; do
	((retries+=1)) &&
	echo "* Attempt $retries..." &&
	today=$(date) &&
	ssh -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no "root@$1" &&
	repeat=false
done

# ssh options
# ConnectTimeout keeps the script from hanging
# BatchMode keeps it from hanging with Host unknown, YES to add to known_hosts
# StrictHostKeyChecking adds the fingerprint automatically.
# Obviously use only for internal networks
