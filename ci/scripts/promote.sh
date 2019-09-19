#!/bin/bash
set -e

source $(dirname $0)/common.sh

buildName=$( cat artifactory-repo/build-info.json | jq -r '.buildInfo.name' )
buildNumber=$( cat artifactory-repo/build-info.json | jq -r '.buildInfo.number' )
packageName="io.spring.gradle.compatibility-test-plugin"
version=$( cat artifactory-repo/build-info.json | jq -r '.buildInfo.modules[0].id' | sed 's/.*:.*:\(.*\)/\1/' )


if [[ $RELEASE_TYPE = "M" ]]; then
	targetRepo="plugins-milestone-local"
elif [[ $RELEASE_TYPE = "RC" ]]; then
	targetRepo="plugins-milestone-local"
elif [[ $RELEASE_TYPE = "RELEASE" ]]; then
	targetRepo="plugins-release-local"
else
	echo "Unknown release type $RELEASE_TYPE" >&2; exit 1;
fi

echo "Promoting ${buildName}/${buildNumber} to ${targetRepo}"

curl \
	-s \
	--connect-timeout 240 \
	--max-time 900 \
	-u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} \
	-H "Content-type:application/json" \
	-d "{\"status\": \"staged\", \"sourceRepo\": \"libs-staging-local\", \"targetRepo\": \"${targetRepo}\"}"  \
	-f \
	-X \
	POST "${ARTIFACTORY_SERVER}/api/build/promote/${buildName}/${buildNumber}" > /dev/null || { echo "Failed to promote" >&2; exit 1; }

if [[ $RELEASE_TYPE = "RELEASE" ]]; then
	curl \
		-s \
		--connect-timeout 240 \
		--max-time 2700 \
		-u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} \
		-H "Content-type:application/json" \
		-d "{\"sourceRepos\": [\"plugins-release-local\"], \"targetRepo\" : \"spring-compatibility-test-plugin-distributions\", \"async\":\"true\"}" \
		-f \
		-X \
		POST "${ARTIFACTORY_SERVER}/api/build/distribute/${buildName}/${buildNumber}" > /dev/null || { echo "Failed to distribute" >&2; exit 1; }

	echo "Waiting for artifacts to be published"
	ARTIFACTS_PUBLISHED=false
	WAIT_TIME=10
	COUNTER=0
	while [ $ARTIFACTS_PUBLISHED == "false" ] && [ $COUNTER -lt 120 ]; do
		result=$( curl -s https://api.bintray.com/packages/"${BINTRAY_SUBJECT}"/"${BINTRAY_REPO}"/"${packageName}" )
		versions=$( echo "$result" | jq -r '.versions' )
		exists=$( echo "$versions" | grep "$version" -o || true )
		if [ "$exists" = "$version" ]; then
			ARTIFACTS_PUBLISHED=true
		fi
		COUNTER=$(( COUNTER + 1 ))
		sleep $WAIT_TIME
	done
	if [[ $ARTIFACTS_PUBLISHED = "false" ]]; then
		echo "Failed to publish"
		exit 1
	else
		curl \
			-s \
			-u ${BINTRAY_USERNAME}:${BINTRAY_API_KEY} \
			-H "Content-Type: application/json" \
			-d '[ { "name": "gradle-plugin", "values": ["io.spring.compatibility-test:io.spring.gradle:compatibility-test-plugin"] } ]' \
			-X POST \
			https://api.bintray.com/packages/${BINTRAY_SUBJECT}/${BINTRAY_REPO}/${packageName}/versions/${version}/attributes  > /dev/null || { echo "Failed to add attributes" >&2; exit 1; }
	fi
fi


echo "Promotion complete"
echo $version > version/version