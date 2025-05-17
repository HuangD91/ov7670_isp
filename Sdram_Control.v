module Sdram_Control(
    //HOST Side
    clk_sdram,
    reset_n,
    //FIFO Write Side 1
    write_data,
    write_en,
    write_addr,
    write_addr_max,
    write_burst_length,
    write_fifo_clr,
    write_fifo_clk,
    //FIFO Read Side 1
    read_data,
    read_en,
    read_addr,
    read_addr_max,
    read_burst_length,
    read_fifo_clr,	
    read_fifo_clk,
    //SDRAM Side
    sdram_addr,
    bank_addr,
    cs_n,
    cke,
    ras_n,
    cas_n,
    we_n,
    dq,
    dqm
);

`include        "Sdram_Params.h"

//	HOST Side
input                           reset_n;                //System Reset
input 							clk_sdram;
//	FIFO Write Side 1
input [`DSIZE-1:0]              write_data;               //Data input
input							              write_en;					//Write Request
input	[`ASIZE-1:0]			        write_addr;				//Write start address
input	[`ASIZE-1:0]			        write_addr_max;			//Write max address
input	[9:0]					            write_burst_length;				//Write length
input							              write_fifo_clr;				//Write register load & fifo clear
input							              write_fifo_clk;				//Write fifo clock
//	FIFO Read Side 1
output [`DSIZE-1:0]             read_data;               //Data output
input						                read_en;					//Read Request
input	[`ASIZE-1:0]			        read_addr;				//Read start address
input	[`ASIZE-1:0]			        read_addr_max;			//Read max address
input	[9:0]					            read_burst_length;				//Read length
input							              read_fifo_clr;				//Read register load & fifo clear
input							              read_fifo_clk;				//Read fifo clock
//	SDRAM Side
output reg [12:0]                  sdram_addr;                     //SDRAM address output
output reg [1:0]                   bank_addr;                     //SDRAM bank address
output reg [1:0]                   cs_n;                   //SDRAM Chip Selects
output  reg                        cke;                    //SDRAM clock enable
output  reg                        ras_n;                  //SDRAM Row address Strobe
output  reg                        cas_n;                  //SDRAM Column address Strobe
output  reg                        we_n;                   //SDRAM write enable
inout   [`DIOSIZE-1:0]            dq;                     //SDRAM data bus
output  reg[`DIOSIZE/8-1:0]          dqm;                    //SDRAM data mask lines

//	Internal Registers/Wires
//	Controller
reg		[`ASIZE-1:0]			mADDR;					//Internal address
reg		[8:0]				    	mLENGTH;				//Internal length
reg		[`ASIZE-1:0]			rwrite_addr;				//Register write address				
reg		[`ASIZE-1:0]			rread_addr;				//Register read address
reg		     			    		WR_MASK;				//Write port active mask
reg		     			    		RD_MASK;				//Read port active mask
reg							       	mWR_DONE;				//Flag write done, 1 pulse SDR_CLK
reg							       	mRD_DONE;				//Flag read done, 1 pulse SDR_CLK
reg							       	mWR,Pre_WR;				//Internal WR edge capture
reg							       	mRD,Pre_RD;				//Internal RD edge capture
reg 	[9:0] 					  ST;						//Controller status
reg		[1:0] 					  CMD;					//Controller command
reg								      PM_STOP;				//Flag page mode stop
reg								      Read;					//Flag read active
reg								      Write;					//Flag write active
reg	    [`DIOSIZE-1:0]    mDATAOUT;               //Controller Data output
wire    [`DIOSIZE-1:0]    mDATAIN;                //Controller Data input
wire    [`DIOSIZE-1:0]    mDATAIN1;                //Controller Data input 1
wire                    CMDACK;                 //Controller command acknowledgement
//	DRAM Control

wire    [12:0]          ISA;                    //SDRAM address output
wire    [1:0]           IBA;                    //SDRAM bank address
wire    [1:0]           ICS_N;                  //SDRAM Chip Selects
wire                    ICKE;                   //SDRAM clock enable
wire                    IRAS_N;                 //SDRAM Row address Strobe
wire                    ICAS_N;                 //SDRAM Column address Strobe
wire                    IWE_N;                  //SDRAM write enable
//	FIFO Control
reg								      OUT_VALID;				//Output data request to read side fifo
reg								      IN_REQ;					//Input	data request to write side fifo
wire	[15:0]					  write_side_fifo_rusedw1;
wire	[15:0]					  read_side_fifo_wusedw1;
//	DRAM Internal Control
wire    [`ASIZE-1:0]    saddr;
wire                    load_mode;
wire                    nop;
wire                    reada;
wire                    writea;
wire                    refresh;
wire                    precharge;
wire                    oe;
wire							      ref_ack;
wire							      ref_req;
wire							      init_req;
wire							      cm_ack;
wire                    last_pm;


control_interface u_control(
                .CLK(clk_sdram),
                .RESET_N(reset_n),
                .CMD(CMD),
                .ADDR(mADDR),
                .REF_ACK(ref_ack),
                .CM_ACK(cm_ack),
                .NOP(nop),
                .READA(reada),
                .WRITEA(writea),
                .REFRESH(refresh),
                .PRECHARGE(precharge),
                .LOAD_MODE(load_mode),
                .SADDR(saddr),
                .REF_REQ(ref_req),
				        .INIT_REQ(init_req),
                .CMD_ACK(CMDACK)
                );

command u_command(
                .CLK(clk_sdram),
                .RESET_N(reset_n),
                .SADDR(saddr),
                .NOP(nop),
                .READA(reada),
                .WRITEA(writea),
                .REFRESH(refresh),
				        .LOAD_MODE(load_mode),
                .PRECHARGE(precharge),
                .REF_REQ(ref_req),
				        .INIT_REQ(init_req),
                .REF_ACK(ref_ack),
                .CM_ACK(cm_ack),
                .OE(oe),
				        .PM_STOP(PM_STOP),
                .SA(ISA),
                .BA(IBA),
                .CS_N(ICS_N),
                .CKE(ICKE),
                .RAS_N(IRAS_N),
                .CAS_N(ICAS_N),
                .WE_N(IWE_N)
                );
                
Sdram_WR_FIFO 	u_write_fifo(
				.data(write_data),
				.wrreq(write_en),
				.wrclk(write_fifo_clk),
				.aclr(write_fifo_clr),
				.rdreq(IN_REQ&WR_MASK),
				.rdclk(clk_sdram),
				.q(mDATAIN1),
				.rdusedw(write_side_fifo_rusedw1)
				);
				
Sdram_RD_FIFO 	u_read_fifo(
				.data(mDATAOUT),
				.wrreq(OUT_VALID&RD_MASK),
				.wrclk(clk_sdram),
				.aclr(read_fifo_clr),
				.rdreq(read_en),
				.rdclk(read_fifo_clk),
				.q(read_data),
				.wrusedw(read_side_fifo_wusedw1)
				);

assign	mDATAIN	=	(WR_MASK)	?	mDATAIN1	:	`DSIZE'hzzzz;
assign  dq = oe ? mDATAIN : `DSIZE'hzzzz;
assign last_pm = (ST==SC_CL+mLENGTH);

always @(posedge clk_sdram)
begin
    sdram_addr <= ISA;
    bank_addr <= IBA;
    cs_n <= ICS_N;
    cke <= ICKE;
    ras_n <= last_pm ? 1'b0 : IRAS_N;
    cas_n <= last_pm ? 1'b1 : ICAS_N;
    we_n <= last_pm ? 1'b0	: IWE_N; 
    PM_STOP <= last_pm ? 1'b1 : 1'b0;
    dqm <= (Read || Write) ? 4'b0000 : 4'b1111;
    mDATAOUT<= dq;
end

always@(posedge clk_sdram or negedge reset_n)
begin
	if(reset_n==0)
	begin
		CMD			<=  0;
		ST			<=  0;
		Pre_RD		<=  0;
		Pre_WR		<=  0;
		Read		<=	0;
		Write		<=	0;
		OUT_VALID	<=	0;
		IN_REQ		<=	0;
		mWR_DONE	<=	0;
		mRD_DONE	<=	0;
	end
	else
	begin
		Pre_RD	<=	mRD;
		Pre_WR	<=	mWR;
		case(ST)
		0:	begin
				if({Pre_RD,mRD}==2'b01)
				begin
					Read	<=	1;
					Write	<=	0;
					CMD		<=	2'b01;
					ST		<=	1;
				end
				else if({Pre_WR,mWR}==2'b01)
				begin
					Read	<=	0;
					Write	<=	1;
					CMD		<=	2'b10;
					ST		<=	1;
				end
			end
		1:	begin
				if(CMDACK==1)
				begin
					CMD<=2'b00;
					ST<=2;
				end
			end
		default:	
			begin	
				if(ST!=SC_CL+SC_RCD+mLENGTH+1)
				ST<=ST+1;
				else
				ST<=0;
			end
		endcase
	
		if(Read)
		begin
			if(ST==SC_CL+SC_RCD+1)
			OUT_VALID	<=	1;
			else if(ST==SC_CL+SC_RCD+mLENGTH+1)
			begin
				OUT_VALID	<=	0;
				Read		<=	0;
				mRD_DONE	<=	1;
			end
		end
		else
		mRD_DONE	<=	0;
		
		if(Write)
		begin
			if(ST==SC_CL-1)
			IN_REQ	<=	1;
			else if(ST==SC_CL+mLENGTH-1)
			IN_REQ	<=	0;
			else if(ST==SC_CL+mLENGTH)
			begin
				Write	<=	0;
				mWR_DONE<=	1;
			end
		end
		else
		mWR_DONE<=	0;

	end
end
//	Internal Address & Length Control
always@(posedge clk_sdram or negedge reset_n)
begin
	if(!reset_n)
	begin
		rwrite_addr		<=	write_addr;
		rread_addr		<=	read_addr;
	end
	else
	begin
		//	Write Side 1
		if(write_fifo_clr)
			rwrite_addr	<=	write_addr;
		else if(mWR_DONE&WR_MASK)
		begin
			if(rwrite_addr<write_addr_max-write_burst_length)
			rwrite_addr	<=	rwrite_addr+write_burst_length;
			else
			rwrite_addr	<=	write_addr;
		end
		//	Read Side 1
		if(read_fifo_clr)
			rread_addr	<=	read_addr;
		else if(mRD_DONE&RD_MASK)
		begin
			if(rread_addr<read_addr_max-read_burst_length)
			rread_addr	<=	rread_addr+read_burst_length;
			else
			rread_addr	<=	read_addr;
		end
	end
end
//	Auto Read/Write Control
always@(posedge clk_sdram or negedge reset_n)
begin
	if(!reset_n)
	begin
		WR_MASK	<=	1'b0;
		RD_MASK	<=	1'b0;
		mWR		<=	0;
		mRD		<=	0;
	end
	else
	begin
		if( (mWR==0) && (mRD==0) && (ST==0) &&
			(WR_MASK==0)	&&	(RD_MASK==0) )
		begin
			//	Read Side 1
			if( (read_side_fifo_wusedw1 < read_burst_length) && (read_fifo_clr==0))
			begin
				mADDR	<=	rread_addr;
				mLENGTH	<=	read_burst_length;
				WR_MASK	<=	1'b0;
				RD_MASK	<=	1'b1;
				mWR		<=	0;
				mRD		<=	1;				
			end
			//	Write Side 1
			else if( (write_side_fifo_rusedw1 >= write_burst_length) && (write_burst_length!=0) && (write_fifo_clr==0))
			begin
				mADDR	<=	rwrite_addr;
				mLENGTH	<=	write_burst_length;
				WR_MASK	<=	1'b1;
				RD_MASK	<=	1'b0;
				mWR		<=	1;
				mRD		<=	0;
			end
		end
		if(mWR_DONE)
		begin
			WR_MASK	<=	0;
			mWR		<=	0;
		end
		if(mRD_DONE)
		begin
			RD_MASK	<=	0;
			mRD		<=	0;
		end
	end
end

endmodule
