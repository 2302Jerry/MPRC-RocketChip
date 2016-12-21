/**************2016/12***********
*Function:         cache_PLRU  
*Organization:     MPRC
*Author:           Yang Ruichao
*Email:            yangruichao@pku.edu.cn
*Filename:         PLRU
*Revision History: v0
********************************/

/*TLB中PseudoLRU与cache 中的PLRU稍有不同：
  cache中的PLRU定义了三个成员方法：access, update, way,并且又开辟一块内存用于存放B标志位
  代表意义分别如下：access 访问cache中某一set的way； update 更新B[0], B[1], B[2]PLRU标志位状态，无论hit或miss都更新；way 替换哪一路
  但是TLB中的PseudoPLRU却不同，定义的成员方法主要有access, replace，并且没有再开辟一块内存用于存放B标志位，也就是说，cache中的PLRU才是通常意义下的Tree-based PLRU
  而TLB中的PseudoLRU并没有增加标志位，没有给标志位开辟内存空间，不算是真正意义上的PLRU，是PLRU的变种
  代表意义分别如下：access 访问某一TLB表项命中
  when (io.req.valid && tlb_hit) {
    plru.access(OHToUInt(tag_cam.io.hits))
  }
  replace 访问某一TLB表项失效，则在该TLB所有表项valid的情况下replace，否则直接将信息填入invalid表项中（即还未使用的表项中）即可
  val plru = new PseudoLRU(entries)   
  val repl_waddr = Mux(has_invalid_entry, invalid_entry, plru.replace)
*/

module PLRU(input clk, 
    input [5:0] set,
    input valid,
    input hit,
    input [3:0] way_in,
    input reset,
    output [3:0] way_out
);

reg[2:0] state_reg[0:63];
reg[2:0] B_idx;
wire[3:0] replaced_way_en;
integer k;

assign replaced_way_en = way_out;

always @(*) begin
	if(hit == 1'h1) begin
		replaced_way_en = way_in;
		case(way_in)
			4'b0001 : B_idx = {2'h1, B_idx[2'h3]};
			4'b0010 : B_idx = {2'b10, B_idx[1'h0]};
			2'b0100 : B_idx = {1'h0, B_idx[1'h1], 1'h1};
			2'b1000 : B_idx = {1'h0, B_idx[1'h1], 1'h0};
			default : B_idx = 3'b000;
		endcase
	end else if(hit == 1'h0) begin
		case(B_idx)
			3'b00x : replaced_way_en = 2'h0; B_idx = {2'h1, B_idx[2'h3]};
			3'b01x : replaced_way_en = 2'h1; B_idx = {2'b10, B_idx[1'h0]};
			3'b1x0 : replaced_way_en = 2'h2; B_idx = {1'h0, B_idx[1'h1], 1'h1};
			3'b1x1 : replaced_way_en = 2'h3; B_idx = {1'h0, B_idx[1'h1], 1'h0};
			default : replaced_way_en = 2'h0;
		endcase
	end
end

always @(posedge clk) begin

if(rest) begin
  for(k = 0; k < 64; k++) begin state_reg[k] <= 3b'000; end
end else if(valid) begin
  state_reg[set] <= B_idx;
end
 
end

endmodule
