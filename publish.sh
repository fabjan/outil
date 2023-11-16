#! /bin/sh

tag_version=$(git tag --points-at HEAD | cut -c 2-)

if [ -z "$tag_version" ]; then
  echo "No tag found at HEAD. Aborting."
  exit 1
fi

package_version=$(grep version gleam.toml | cut -d '"' -f 2)

if [ "$tag_version" != "$package_version" ]; then
  echo "Tag version ($tag_version) does not match package version ($package_version). Aborting."
  exit 1
fi

gleam publish
