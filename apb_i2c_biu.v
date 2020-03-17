//i2c biu is reaponsbile for the data transfer from apb to single line
// I2C biu 模块的目的是为了将AHB 接口的信号转换成简单的读写信号来实现对reg的操作
module apb_i2c_biu #(
	parameter ADDR_SLICE_LHS = 5, // addres [4:0] 
	parameter APB_DATA_WIDTH = 32
)
(
// signals connect to APB module 
	input							pclk,
	input							presetn, // reset
	input 							psel, // select signal
	input	[ADDR_SLICE_LHS-1 : 0] 	paddr, // 5bit addres
	input							pwrite,
	input 							penable,
	input	[APB_DATA_WIDTH-1 : 0]	pwdata,
	output	reg [APB_DATA_WIDTH-1 : 0] prdata,
//signals connect to register module
	input	[15:0]					iprdata, // ?
	output							wr_en,
									rd_en,
	output	[ADDR_SLICE_LHS-3:0]	reg_addr, // ahb addres searching
	output	[3:0]					byte_en,
	output	reg	[31:0]				ipwdata
);

/*
写时序：片选信号（psl）拉高，同时penable 为高，pwrite 为高表示允许进行写操作，然后输出写信号，输出数据data
读时序：片选拉高，pwrite 拉低，penable 为高后，输出读信号，将对应数据读入prdata中
*/

assign wr_en = psel & penable & pwrite; // 写信号的要求
assign rd_en = psel & !penable & !pwrite; // 读信号要提前产生，因为要求把数据提前放到APB总线上

assign reg_addr = paddr[ADDR_SLICE_LHS-1:2]; //因为ahp的地址累加方式是048c，实际的reg只用前三位

//写过程，如果数据变换就直接写到输出的reg中
always @(pwdata) begin
	ipwdata = 32'b0;
	ipwdata [APB_DATA_WIDTH-1:0] = pwdata[APB_DATA_WIDTH-1:0]; //apb总线上的数据每次发生变化，就将数据传输到输出reg中
end

assign byte_en = 4'b1111; // 按照字寻址

// 读过程
always @ (posedge pclk or negedge presetn) begin
	if(presetn == 1'b0) begin
		prdata <= {APB_DATA_WIDTH{1'b0}}; //apb 读寄存器中的数据清零
	end
	else begin
		if (rd_en) begin
			prdata <= {16'b0,iprdata}; // 将读入的数据保存到apb reg中
		end
	end
end







