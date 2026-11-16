#!/usr/bin/env bash
set -e

# splitnets output must not depend on the memory layout
cat > splitnets_order.v <<'EOT'
module sub(input [3:0] as, input [3:0] bs, output [3:0] ys);
	assign ys = as & bs;
endmodule
module top(input [3:0] a, input [3:0] b, output [3:0] y);
	sub p(a, b, y);
endmodule
EOT

run() {
	${YOSYS} -q -p "$1 read_verilog splitnets_order.v; hierarchy -top top; splitnets -ports; write_rtlil $2"
}

run "" splitnets_order.1.il
run "read_verilog splitnets_order.v; hierarchy -top top; opt_clean; design -reset;" splitnets_order.2.il
run "read_verilog splitnets_order.v; design -reset; read_verilog splitnets_order.v; design -reset;" splitnets_order.3.il
cmp splitnets_order.1.il splitnets_order.2.il
cmp splitnets_order.1.il splitnets_order.3.il
rm -f splitnets_order.v splitnets_order.?.il
