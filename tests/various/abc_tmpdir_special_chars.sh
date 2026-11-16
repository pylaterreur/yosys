#!/usr/bin/env bash
set -e

# The abc, abc9 and abc_new passes must work when TMPDIR contains spaces or
# characters that the shell expands. (A quote character in the name cannot work:
# ABC treats every quote character as a quote, even inside a quoted word.)

cat > abc_tmpdir_special_chars.v <<'EOT'
module top(input [3:0] a, b, output [4:0] y);
	assign y = a + b;
endmodule
EOT

run() {
	dir="$1"
	shift
	rm -rf "$dir"
	mkdir "$dir"
	if ! TMPDIR="$PWD/$dir" "$@" > abc_tmpdir_special_chars.log 2>&1; then
		cat abc_tmpdir_special_chars.log
		echo "failed with TMPDIR='$PWD/$dir': $*" >&2
		exit 1
	fi
}

# the private directories are removed again
check() {
	run "$@"
	if [ -n "$(ls -A "$1")" ]; then
		echo "left behind in '$1': $(ls -A "$1")" >&2
		exit 1
	fi
	rmdir "$1"
}

for dir in "abc tmpdir with spaces" 'abc$HOME$tmpdir'; do
	check "$dir" ${YOSYS} -q -p "read_verilog abc_tmpdir_special_chars.v; synth -top top; abc"
	check "$dir" ${YOSYS} -q -p "read_verilog abc_tmpdir_special_chars.v; synth -top top; abc -lut 4"
	check "$dir" ${YOSYS} -q -p "read_verilog abc_tmpdir_special_chars.v; synth_ecp5 -top top"
	check "$dir" ${YOSYS} -q -p "read_verilog abc_tmpdir_special_chars.v; synth_ecp5 -abc9 -top top"
	# abc_new does not remove its directory, and the liberty cache stays in TMPDIR
	run "$dir" ${YOSYS} -q -p "read_verilog abc_tmpdir_special_chars.v; synth -top top; abc_new -liberty ../liberty/normal.lib"
	rm -rf "$dir"
done

rm -f abc_tmpdir_special_chars.v abc_tmpdir_special_chars.log
