#!/usr/bin/env bash
set -e

# A backend whose output cannot be written must make the command fail
# (/dev/full: ENOSPC).
if [ ! -w /dev/full ]; then
	echo "/dev/full is not available, skipping"
	exit 0
fi

cat > backend_write_error.v <<'EOT'
module top(input a, b, output y);
	assign y = a & b;
endmodule
EOT

expect_write_error() {
	set +e
	"$@" > backend_write_error.log 2>&1
	status=$?
	set -e
	if [ $status -ne 1 ]; then
		cat backend_write_error.log
		echo "expected exit status 1 from: $*, got $status" >&2
		exit 1
	fi
	grep -q "Error writing the output of" backend_write_error.log
}

for backend in write_json write_verilog write_rtlil write_blif; do
	expect_write_error ${YOSYS} -q -p "read_verilog backend_write_error.v; hierarchy -top top; $backend /dev/full"
done
expect_write_error ${YOSYS} -q -b rtlil -o /dev/full backend_write_error.v

# gzip output reaches the file when the stream is closed
rm -f backend_write_error.json.gz
ln -s /dev/full backend_write_error.json.gz
expect_write_error ${YOSYS} -q -p "read_verilog backend_write_error.v; write_json backend_write_error.json.gz"
rm -f backend_write_error.json.gz

# the interactive shell reports the error and goes on
printf 'read_verilog backend_write_error.v\nwrite_json /dev/full\nwrite_json backend_write_error.json\n' | ${YOSYS} -q > backend_write_error.log 2>&1
grep -q "Error writing the output of" backend_write_error.log
grep -q '"top"' backend_write_error.json

# a file that can be written is still fine
rm -f backend_write_error.json
${YOSYS} -q -p "read_verilog backend_write_error.v; write_json backend_write_error.json"
grep -q '"top"' backend_write_error.json
rm -f backend_write_error.v backend_write_error.log backend_write_error.json
