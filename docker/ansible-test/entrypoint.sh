#!/bin/bash
set -e

# Extract collection to path needed for ansible-test sanity
mkdir -p /ansible_collections/placeholder_namespace/placeholder_name
pushd ansible_collections/ > /dev/null
pushd placeholder_namespace/placeholder_name/ > /dev/null

echo "Copying and extracting collection archive..."
wget $ARCHIVE_URL -O archive.tar.gz
tar -xzf archive.tar.gz

# Get variables from collection metadata
read NAMESPACE NAME VERSION < <(python3 <<EOF
import json
with open('MANIFEST.json') as fp:
    metadata = json.load(fp)['collection_info']
values = metadata['namespace'], metadata['name'], metadata['version']
print(*values)
EOF
)

# Rename placeholders in path
popd > /dev/null
mv placeholder_namespace/placeholder_name placeholder_namespace/"$NAME"
mv placeholder_namespace/ "$NAMESPACE"
cd /ansible_collections/"$NAMESPACE"/"$NAME"

# Set env var so ansible --version does not error with getpass.getuser()
export USER=user1

echo "Using $(ansible --version | head -n 1), $(python --version)"

echo "Running ansible-test sanity on $NAMESPACE-$NAME-$VERSION ..."
# NOTE: skipping some sanity tests
# "import" and "validate-modules" require sandboxing
# "pslint" throws ScriptRequiresMissingModules when container is not run as root
# "ansible-doc" is already called for all plugins in import process
ansible-test sanity --skip-test import --skip-test validate-modules --skip-test pslint --skip-test ansible-doc --color no --failure-ok

exec "$@"
