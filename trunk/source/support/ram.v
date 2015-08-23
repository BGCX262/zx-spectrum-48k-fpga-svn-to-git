`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        Dept. Architecture and Computing Technology. University of Seville
// Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
// 
// Create Date:    19:13:39 4-Apr-2012 
// Design Name:    ZX Spectrum
// Module Name:    ram32k
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 1.00 - File Created
// Additional Comments: GPL License policies apply to the contents of this file.
//
//////////////////////////////////////////////////////////////////////////////////

/*
This module implements a RAM controller using FPGA internal RAMB resources.
*/
module ram_controller (
	input clk,
	// Bank 1 (VRAM)
	input [15:0] a1,
	input cs1_n,
	input oe1_n,
	input we1_n,
	input [7:0] din1,
	output [7:0] dout1,
	// Bank 2 (upper RAM)
	input [15:0] a2,
	input cs2_n,
	input oe2_n,
	input we2_n,
	input [7:0] din2,
	output [7:0] dout2
	);

	// virtual RAMs
	reg [7:0] vram [0:16383];
	reg [7:0] sram [0:32767]; // use 16383 if synthesis fails due to not enough FPGA resources

	// set when there has been a high to low transition in the corresponding signal
	wire bank1read, bank1write, bank2read, bank2write;

	wire [3:0] ma;

	assign ma[3] = cs1_n | oe1_n;
	assign ma[2] = cs2_n | oe2_n;
	assign ma[1] = cs1_n | we1_n;
	assign ma[0] = cs2_n | we2_n;

	reg [3:0] sh = 4'b1111;

	always @(posedge clk)
	begin
		sh <= ma;
	end

	assign bank1read  = sh[3] & ~ma[3];
	assign bank2read  = sh[2] & ~ma[2];
	assign bank1write = sh[1] & ~ma[1];
	assign bank2write = sh[0] & ~ma[0];

	reg [15:0] ra1;
	reg [15:0] ra2;
	reg [7:0] rdin1;
	reg [7:0] rdin2;
	
	reg [7:0] rdout1;
	assign dout1 = rdout1;
	reg [7:0] rdout2;
	assign dout2 = rdout2;

	// ff's to store pending memory requests
	reg pendingreadb1 = 0;
	reg pendingwriteb1 = 0;
	reg pendingreadb2 = 0;
	reg pendingwriteb2 = 0;
	
	// ff's to store current memory requests
	reg reqreadb1 = 0;
	reg reqreadb2 = 0;
	reg reqwriteb1 = 0;
	reg reqwriteb2 = 0;
	
	reg state = 1;
	always @(posedge clk) begin
		// get requests from the two banks
		if (bank1read) begin
			ra1 <= a1;
			pendingreadb1 <= 1;
			pendingwriteb1 <= 0;
		end
		else if (bank1write) begin
			ra1 <= a1;
			rdin1 <= din1;
			pendingwriteb1 <= 1;
			pendingreadb1 <= 0;
		end
		if (bank2read) begin
			ra2 <= a2;
			pendingreadb2 <= 1;
			pendingwriteb2 <= 0;
		end
		else if (bank2write) begin
			ra2 <= a2;
			rdin2 <= din2;
			pendingwriteb2 <= 1;
			pendingreadb2 <= 0;
		end
		
		// reads from bank1 have the higher priority, then writes to bank1,
		// the reads from bank2, then writes from bank2.
		// Reads and writes to bank2 are mutually exclusive, though, as only the CPU
		// performs those operations. So they are with respect to bank1.
		case (state)
			0 : begin
					if (reqreadb1 || reqwriteb1) begin
						if (reqwriteb1) begin       // if this is a write operation...
							pendingwriteb1 <= 0;     // accept it, and mark pending operation as cleared
							vram[ra1[13:0]] <= rdin1; // put data into virtual SRAM
						end
						else begin
							pendingreadb1 <= 0;  // else, this is a read operation...
						end
						state <= 1;             // if either request has been accepted, proceed to next phase.
					end
				   else if (reqreadb2 || reqwriteb2) begin	// do the same with requests to bank 2...
						if (reqwriteb2) begin
							pendingwriteb2 <= 0;
							sram[ra2[14:0]] <= rdin2; // put data into virtual SRAM
				  end
						else begin
							pendingreadb2 <= 0;
						end
						state <= 1;
					end
				  end
			1 : begin
					if (reqreadb1) begin		     // for read requests, read the SRAM data bus and store into the corresponding data output register
						rdout1 <= vram[ra1[13:0]]; // get data from virtual SRAM
					end
					else if (reqreadb2) begin
						rdout2 <= sram[ra2[14:0]]; // get data from virtual SRAM
					end
					reqreadb1 <= pendingreadb1;	// current request has finished, so update current requests with pending requests to serve  the next one
					reqreadb2 <= pendingreadb2;
					reqwriteb1 <= pendingwriteb1;					
					reqwriteb2 <= pendingwriteb2;
					if (pendingreadb1 || pendingreadb2 || pendingwriteb1 || pendingwriteb2)
						state <= 0;
				 end
		endcase
	end
endmodule
