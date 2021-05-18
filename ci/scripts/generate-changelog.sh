#!/bin/bash
set -e

CONFIG_DIR=git-repo/ci/config
version=$( cat artifactory-repo/build-info.json | jq -r '.buildInfo.modules[0].id' | sed 's/.*:.*:\(.*\)/\1/' )

java -jar /github-changelog-generator.jar \
  --changelog.repository=spring-gradle-plugins/compatibility-test-plugin \
  ${version} generated-changelog/changelog.md

echo ${version} > generated-changelog/version
echo v${version} > generated-changelog/tag
