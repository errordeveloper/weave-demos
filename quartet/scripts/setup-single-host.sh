#!/bin/sh -ex

source $(git rev-parse --show-toplevel)/quartet/scripts/defaults.sh

create_machine_with_proxy_setup "${MACHINE_NAME_PREFIX}" '5'
