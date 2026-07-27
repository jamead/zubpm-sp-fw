///////////////////////////////////////////////////////////////////////////////
// 
// Brookhaven National Laborotory
// Chris Danneil 
// 
// 29 bit in, 26 bit out CORDIC rectangular to polar converter
// Sequential conversion takes 36 clock cycles to complete
// Created September 2019
// Output registers modified to provide appropriate Gain and bit width.
// 
// Magnitude gain is 0.103 
//
// Phase output is in CORDIC angle. Multiply by 360/2^26 for degrees 
// or pi/2^25 for radians.
//
// corrected error in cordic_angle[0] table
// additional comments between brackets {}
////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	../rtl/seqpolar.v
//
// Project:	A series of CORDIC related projects
//
// Purpose:	This is a rectangular to polar conversion routine based upon an
//		internal CORDIC implementation.  Basically, the input is
//	provided in i_xval and i_yval.  The internal CORDIC rotator will rotate
//	(i_xval, i_yval) until i_yval is approximately zero.  The resulting
//	xvalue and phase will be placed into o_xval and o_phase respectively.
//
//	This particular version of the polar to rectangular CORDIC converter
//	converter processes a somple one at a time.  It is completely
//	sequential, not parallel at all.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017-2018, Gisselquist Technology, LLC
//
// This file is part of the CORDIC related project set.
//
// The CORDIC related project set is free software (firmware): you can
// redistribute it and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation, either version
// 3 of the License, or (at your option) any later version.
//
// The CORDIC related project set is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
// General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  (It's in the $(ROOT)/doc directory.  Run make
// with no target there if the PDF file isn't present.)  If not, see
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module	seqpolar(i_clk, i_reset, i_stb, i_xval, i_yval, i_aux, o_busy,
		o_done, o_mag, o_phase, o_aux);
	localparam	IW=29,	// The number of bits in our inputs
			OW=26,// The number of output bits to produce
			NSTAGES=33,
			XTRA= 3,// Extra bits for internal precision
			WW=35,	// Our working bit-width
			PW=36;	// Bits in our phase variables
	input	wire	i_clk, i_reset, i_stb;
	input	wire	signed	[(IW-1):0]	i_xval, i_yval;
	output	wire				o_busy;
	output	reg				o_done;
	output	reg	signed	[(OW-1):0]	o_mag;
	output	reg		[(OW-1):0]	o_phase;
	input	wire				i_aux;
	output	reg				o_aux;
	// First step: expand our input to our working width.
	// This is going to involve extending our input by one
	// (or more) bits in addition to adding any xtra bits on
	// bits on the right.  The one bit extra on the left is to
	// allow for any accumulation due to the cordic gain
	// within the algorithm.
	// 
	wire	signed [(WW-1):0]	e_xval, e_yval;
	assign	e_xval = { {(2){i_xval[(IW-1)]}}, i_xval, {(WW-IW-2){1'b0}} };
	assign	e_yval = { {(2){i_yval[(IW-1)]}}, i_yval, {(WW-IW-2){1'b0}} };

	// Declare variables for all of the separate stages
	reg	signed	[(WW-1):0]	xv, yv, prex, prey;
	reg		[(PW-1):0]	ph, preph;

	//
	// Handle the auxilliary logic.
	//
	// The auxilliary bit is designed so that you can place a valid bit into
	// the CORDIC function, and see when it comes out.  While the bit is
	// allowed to be anything, the requirement of this bit is that it *must*
	// be aligned with the output when done.  That is, if i_xval and i_yval
	// are input together with i_aux, then when o_xval and o_yval are set
	// to this value, o_aux *must* contain the value that was in i_aux.
	//
	reg		aux;

	always @(posedge i_clk)
	if (i_reset)
		aux <= 0;
	else if ((i_stb)&&(!o_busy))
		aux <= i_aux;

	// First stage, map to within +/- 45 degrees
	always @(posedge i_clk)
		case({i_xval[IW-1], i_yval[IW-1]})
		2'b01: begin // Rotate by -315 degrees
			prex <=  e_xval - e_yval;
			prey <=  e_xval + e_yval;
			preph <= 36'he00000000;
			end
		2'b10: begin // Rotate by -135 degrees
			prex <= -e_xval + e_yval;
			prey <= -e_xval - e_yval;
			preph <= 36'h600000000;
			end
		2'b11: begin // Rotate by -225 degrees
			prex <= -e_xval - e_yval;
			prey <=  e_xval - e_yval;
			preph <= 36'ha00000000;
			end
		// 2'b00:
		default: begin // Rotate by -45 degrees
			prex <=  e_xval + e_yval;
			prey <= -e_xval + e_yval;
			preph <= 36'h200000000;
			end
		endcase
	//
	// In many ways, the key to this whole algorithm lies in the angles
	// necessary to do this.  These angles are also our basic reason for
	// building this CORDIC in C++: Verilog just can't parameterize this
	// much.  Further, these angle's risk becoming unsupportable magic
	// numbers, hence we define these and set them in C++, based upon
	// the needs of our problem, specifically the number of stages and
	// the number of bits required in our phase accumulator
	//
	reg	[35:0]	cordic_angle [0:63];
	reg	[35:0]	cangle;

	initial	cordic_angle[ 0] = 36'h12e40_51da; //  26.565051 deg  {(python - math.atan2(1,2)*2**36/(2*math.pi))}
	initial	cordic_angle[ 1] = 36'h09fb3_85b5; //  14.036243 deg  {x = atan2(1., pow(2,k+1));                  }
	initial	cordic_angle[ 2] = 36'h05111_1d41; //   7.125016 deg  { 	deg = x * 180.0 / M_PI;               }
	initial	cordic_angle[ 3] = 36'h028b0_d430; //   3.576334 deg
	initial	cordic_angle[ 4] = 36'h0145d_7e15; //   1.789911 deg
	initial	cordic_angle[ 5] = 36'h00a2f_61e5; //   0.895174 deg
	initial	cordic_angle[ 6] = 36'h00517_c551; //   0.447614 deg
	initial	cordic_angle[ 7] = 36'h0028b_e534; //   0.223811 deg
	initial	cordic_angle[ 8] = 36'h00145_f2eb; //   0.111906 deg
	initial	cordic_angle[ 9] = 36'h000a2_f980; //   0.055953 deg
	initial	cordic_angle[10] = 36'h00051_7cc1; //   0.027976 deg
	initial	cordic_angle[11] = 36'h00028_be60; //   0.013988 deg
	initial	cordic_angle[12] = 36'h00014_5f30; //   0.006994 deg
	initial	cordic_angle[13] = 36'h0000a_2f98; //   0.003497 deg
	initial	cordic_angle[14] = 36'h00005_17cc; //   0.001749 deg
	initial	cordic_angle[15] = 36'h00002_8be6; //   0.000874 deg
	initial	cordic_angle[16] = 36'h00001_45f3; //   0.000437 deg
	initial	cordic_angle[17] = 36'h00000_a2f9; //   0.000219 deg
	initial	cordic_angle[18] = 36'h00000_517c; //   0.000109 deg
	initial	cordic_angle[19] = 36'h00000_28be; //   0.000055 deg
	initial	cordic_angle[20] = 36'h00000_145f; //   0.000027 deg
	initial	cordic_angle[21] = 36'h00000_0a2f; //   0.000014 deg
	initial	cordic_angle[22] = 36'h00000_0517; //   0.000007 deg
	initial	cordic_angle[23] = 36'h00000_028b; //   0.000003 deg
	initial	cordic_angle[24] = 36'h00000_0145; //   0.000002 deg
	initial	cordic_angle[25] = 36'h00000_00a2; //   0.000001 deg  {We could stop here since these factors  } 
	initial	cordic_angle[26] = 36'h00000_0051; //   0.000000 deg  {are below the final resolution and will }
	initial	cordic_angle[27] = 36'h00000_0028; //   0.000000 deg  {be truncated. It will not save any      }
	initial	cordic_angle[28] = 36'h00000_0014; //   0.000000 deg  {resources though. And the full length   }
	initial	cordic_angle[29] = 36'h00000_000a; //   0.000000 deg  {is within the latency limit.            }
	initial	cordic_angle[30] = 36'h00000_0005; //   0.000000 deg  { Adjust last_state assignment to change }
	initial	cordic_angle[31] = 36'h00000_0002; //   0.000000 deg
	initial	cordic_angle[32] = 36'h00000_0001; //   0.000000 deg
	initial	cordic_angle[33] = 36'h00000_0000; //   0.000000 deg
	initial	cordic_angle[34] = 36'h00000_0000; //   0.000000 deg
	initial	cordic_angle[35] = 36'h00000_0000; //   0.000000 deg
	initial	cordic_angle[36] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[37] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[38] = 36'h00000_0000; //   0.000000 deg  {Truncated table because the routine }
//	initial	cordic_angle[39] = 36'h00000_0000; //   0.000000 deg  {never goes here.                    }
//	initial	cordic_angle[40] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[41] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[42] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[43] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[44] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[45] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[46] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[47] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[48] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[49] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[50] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[51] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[52] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[53] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[54] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[55] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[56] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[57] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[58] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[59] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[60] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[61] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[62] = 36'h00000_0000; //   0.000000 deg
//	initial	cordic_angle[63] = 36'h00000_0000; //   0.000000 deg
	// Std-Dev    : 0.15 (Units)
	// Phase Quantization: 0.392699 (Radians)
	// Gain is 1.164435
	// You can annihilate this gain by multiplying by 32'hdbd95b16
	// and right shifting by 32 bits.

	reg		idle, pre_valid;
	reg	[5:0]	state;

	wire	last_state;
	assign	last_state = (state >= 34);

	initial	idle = 1'b1;
	always @(posedge i_clk)
	if (i_reset)
		idle <= 1'b1;
	else if (i_stb)
		idle <= 1'b0;
	else if (last_state)
		idle <= 1'b1;

	initial	pre_valid = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		pre_valid <= 1'b0;
	else
		pre_valid <= (i_stb)&&(idle);

	initial	state = 0;
	always @(posedge i_clk)
	if (i_reset)
		state <= 0;
	else if (idle)
		state <= 0;
	else if (last_state)
		state <= 0;
	else
		state <= state + 1;

	always @(posedge i_clk)
		cangle <= cordic_angle[state[5:0]];

	// Here's where we are going to put the actual CORDIC
	// rectangular to polar loop.  Everything up to this
	// point has simply been necessary preliminaries.
	always @(posedge i_clk)
	if (pre_valid)
	begin
		xv <= prex;
		yv <= prey;
		ph <= preph;
	end else if (yv[(WW-1)]) // Below the axis
	begin
		// If the vector is below the x-axis, rotate by
		// the CORDIC angle in a positive direction.
		xv <= xv - (yv>>>state);
		yv <= yv + (xv>>>state);
		ph <= ph - cangle;
	end else begin
		// On the other hand, if the vector is above the
		// x-axis, then rotate in the other direction
		xv <= xv + (yv>>>state);
		yv <= yv - (xv>>>state);
		ph <= ph + cangle;
	end

	always @(posedge i_clk)
	if (i_reset)
		o_done <= 1'b0;
	else
		o_done <= (last_state);

	// Round our magnitude towards even
	wire	[(WW-1):0]	final_mag;

	assign	final_mag = xv + $signed({{(OW){1'b0}},
				xv[(WW-OW)],
				{(WW-OW-1){!xv[WW-OW]}}});

	always @(posedge i_clk)
	if (last_state)
	begin
		o_mag   <= final_mag[(WW-2):(WW-OW-1)];  //{shifted output to right 1 bit and truncated to 26 bits }
		//o_mag   <= final_mag[(WW+1):(WW-OW-4)];  // modified to give a gain of 8 to match parallel cordic  12-20-19
		//o_mag   <= final_mag[(WW-5):(WW-OW+2)];  // modified to give a gain of -8 to match parallel cordic  12-20-19		
		o_phase <= ph[(PW-1):(PW-OW)];
		o_aux <= aux;
	end

	assign	o_busy = !idle;

	// Make Verilator happy with pre_.val
	// verilator lint_off UNUSED
	wire	[(WW-OW):0] unused_val;
	assign	unused_val = { final_mag[WW-1], final_mag[(WW-OW-1):0] };
	// verilator lint_on UNUSED
endmodule
