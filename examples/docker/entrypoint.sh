#!/bin/bash

# Remove the final exec from the entrypoint
sed -i.bak \
  -e 's|^exec "\$\@"$|exit 0|g' /usr/local/bin/docker-entrypoint.sh

# Execute the modified entrypoint, it will eventually exit
./usr/local/bin/docker-entrypoint.sh mongod

exit 0
