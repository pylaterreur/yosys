#!/usr/bin/env bash
set -e

# write_edif and write_smt2 output must not depend on the memory layout
{
	for i in $(seq 0 19); do
		echo "module leaf$i(input a, output y); assign y = ~a; endmodule"
	done
	echo "module top(input a, output y);"
	echo "	wire [20:0] w;"
	echo "	assign w[0] = a;"
	for i in $(seq 0 19); do
		echo "	leaf$i u$i(.a(w[$i]), .y(w[$((i + 1))]));"
	done
	echo "	assign y = w[20];"
	echo "endmodule"
} > write_edif_smt2_order.v

run() {
	${YOSYS} -q -p "$1 read_verilog write_edif_smt2_order.v; hierarchy -top top; write_edif write_edif_smt2_order.$2.edif; write_smt2 write_edif_smt2_order.$2.smt2"
}

run "" 1
run "read_verilog -sv write_edif_smt2_order.v; design -reset;" 2
run "read_verilog write_edif_smt2_order.v; design -reset; read_verilog write_edif_smt2_order.v; design -reset;" 3
for ext in edif smt2; do
	cmp write_edif_smt2_order.1.$ext write_edif_smt2_order.2.$ext
	cmp write_edif_smt2_order.1.$ext write_edif_smt2_order.3.$ext
done
rm -f write_edif_smt2_order.v write_edif_smt2_order.?.edif write_edif_smt2_order.?.smt2
