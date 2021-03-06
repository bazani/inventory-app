#!/usr/bin/env bash

set -e

# This script should only be used when the
# volume defined in docker-compose.yml should
# need to be snapshotted and pushed. 

# This script will take the volume and snapshot 
# that volume with metadata about the branch 
# and build and push it back to Flocker Hub.

# -------------------- Params ---------------------------------------
# VOLUMESET        is a Flocker Hub Volumeset, which owns snapshots and variants
# GITBRANCH        is the Github Branch name being built, it is provided by the Jenkins env.
# JENKINSBUILDN    is the Jenkins Build Number, it is provided by the Jenkins env.
# JENKINSBUILDID   is the Jenkins Build ID, it is provided by the Jenkins env.
# JENKINSBUILDURL  is the Jenkins Build ID URL, it is provided by the Jenkins env.
# TEST			   is the Test that was run with the snapshot.
# JENKINSNODE      is the Jenkins node the snapshot was used on in the build,
#                  it is provided by the Jenkins env.
# --------------------- END -----------------------------------------

VOLUMESET=$1
GITBRANCH=$2
JENKINSBUILDN=$3
JENKINSBUILDID=$4
JENKINSBUILDURL=$5
TEST=$6
JENKINSNODE=$7

fli='docker run --rm --privileged -v /var/log/:/var/log/ -v /chq:/chq:shared -v /root:/root -v /lib/modules:/lib/modules clusterhq/fli'

# Check for "needed" vars
if [ -z "$VOLUMESET" ]; then
    echo "VOLUMESET was unset, exiting"
    exit 1
fi  

# If failed test, provide a manifest to re-create err state.
echo "Checking for erros and snapshoting database on test failure."
if [[ "$TEST" == *"Failed-"* ]]
then
echo "Found failed test."
echo "Getting the active volume from the application."
WORKINGVOL=$(cat inventory-app/docker-compose.yml | grep -E -o  '\/chq\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | rev |  cut -f1 -d"/" | rev)
echo "Volume being used was $WORKINGVOL"

IDOFWORKINGVOL=$($fli list -v ${WORKINGVOL} | grep ${WORKINGVOL} | head -1 | awk '{print $1}')
SNAPNAME="${GITBRANCH}-snapshotOfDb-${TEST}-build-${JENKINSBUILDN}"
BRANCHNAME="${GITBRANCH}-${TEST}-build-${JENKINSBUILDN}"

echo "Creating snapshot $SNAPNAME"
echo "Running: fli snapshot -b ${BRANCHNAME} \
-a jenkins_build_number=${JENKINSBUILDN},build_id=${JENKINSBUILDID},build_URL=${JENKINSBUILDURL},ran_test=${TEST},built_on_jenkins_vm=${JENKINSNODE//[[:blank:]]/} \
-d 'a snapshot of ${WORKINGVOL} for test ${TEST}' \
${VOLUMESET}:${IDOFWORKINGVOL} ${SNAPNAME}"

VOLSNAP=$($fli snapshot -b ${BRANCHNAME} \
-a jenkins_build_number=${JENKINSBUILDN},build_id=${JENKINSBUILDID},build_URL=${JENKINSBUILDURL},ran_test=${TEST},built_on_jenkins_vm=${JENKINSNODE//[[:blank:]]/} \
-d "a snapshot of ${WORKINGVOL} for test ${TEST}" \
${VOLUMESET}:${IDOFWORKINGVOL} ${SNAPNAME})

echo "Took snapshot: ${SNAPNAME} of volume: ${IDOFWORKINGVOL}"

echo "Producing manifest for failed test: ${TEST}"
cat >> testfailures.txt <<EOL
  USE THIS MANIFEST TO PULL ERROR STATE for ${TEST}
  Hint: use with fli-docker and you may need to change the token
 
  docker_app: docker-compose.yml

  flocker_hub:
      endpoint: https://data.flockerhub.clusterhq.com

  volumes:
      - name: rethink-data
      snapshot: ${SNAPNAME}
      volumeset: ${VOLUMESET}
EOL

echo "Syncing volumset back to FlockerHub"
$fli sync $VOLUMESET
# only push on failure, if everything is A OK, no need.
echo "Pushing $VOLUMESET:$SNAPNAME to FlockerHub."
$fli push $VOLUMESET:$SNAPNAME
echo "Showing specific snapshots for this builds branch."
$fli list -b ${BRANCHNAME}
else
echo "No snapshots taken, no failures found."
fi


