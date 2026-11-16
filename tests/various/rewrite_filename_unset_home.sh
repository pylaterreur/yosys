#!/usr/bin/env bash
set -e

# A file name starting with "~/" must not crash when HOME is not set.
set +e
env -u HOME ${YOSYS} -q -p 'read_verilog ~/rewrite_filename_unset_home_missing.v' > rewrite_filename_unset_home.log 2>&1
status=$?
set -e
cat rewrite_filename_unset_home.log
if [ $status -ne 1 ]; then
	echo "expected exit status 1 (error), got $status" >&2
	exit 1
fi
grep -q "not found or is a directory" rewrite_filename_unset_home.log
rm -f rewrite_filename_unset_home.log
