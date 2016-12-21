/**************2016/12***********
*Function:         TLB_PseudoLRU update
*Organization:     MPRC
*Author:           Yang Ruichao
*Email:            yangruichao@pku.edu.cn
*Filename:         PLRU_TLB
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
  has_invalid_entry_in猜测是文档中未标注意义的T_486 ，表示是否有invalid表项，如有，则不需替换算法生效，只需将需要的块填入invalid位置即可
  has_invalid_entry_out,猜测是文档中未标注意义的T_504
  invalid_entry,猜测是文档中未标注的T511[7:0]
*/


module PLRU(
    input hits[7:0],//way_in[7:0],
    input T_421[7:0],//state_reg_in,
	output GEN_42[7:0],//state_reg_out
	input T_486,//has_invalid_entry_in
	output T_504,//has_invalid_entry_out
	input T511[7:0],//invalid_entry[7:0]
);

wire [7:0] way_in;
reg [7:0] state_reg_in;
reg [7:0] state_reg_out;
wire has_invalid_entry_in;
wire has_invalid_entry_out;
wire [7:0] invalid_entry;

assign way_in = hits;
assign state_reg_in = T_421;
assign stage_reg_out = GEN_42;
assign has_invalid_entry_in = T486;
assign has_invalid_entry_out = T504;
assign invalid_entry = T511;
assign has_invalid_entry_out = has_invalid_entry_in;

always @(*) begin
	case(way_in)
			8'b00000001 : state_reg_out = {state_reg_in[0], 2'b11, state_reg_in[3], 1'b1, state_reg_in[7:5]};
			8'b00000010 : state_reg_out = {state_reg_in[0], 2'b11, state_reg_in[3], 1'b0, state_reg_in[7:5]};
			8'b00000100 : state_reg_out = {state_reg_in[0], 2'b10, state_reg_in[4:3], 1'b1, state_reg_in[7:6]};
			8'b00001000 : state_reg_out = {state_reg_in[0], 2'b10, state_reg_in[4:3], 1'b0, state_reg_in[7:6]};
			8'b00010000 : state_reg_out = {state_reg_in[0], 1'b0, state_reg_in[2], 1'b1, state_reg_in[5:4], 1'b1, state_reg_in[7]};
			8'b00100000 : state_reg_out = {state_reg_in[0], 1'b0, state_reg_in[2], 1'b0, state_reg_in[5:4], 1'b1, state_reg_in[7]};
			8'b01000000 : state_reg_out = {state_reg_in[0], 1'b0, state_reg_in[2], 1'b0, state_reg_in[6:4], 1'b1};
			8'b10000000 : state_reg_out = {state_reg_in[0], 1'b0, state_reg_in[2], 1'b0, state_reg_in[6:4], 1'b0};
			default : state_reg_out = 8'b00000000;
	endcase
end

endmodule
