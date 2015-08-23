Implementation of ZX Spectrum 48K
Based on ULA core from opencores.com by Miguel Angel Rodriguez Jodar

There are a number of Xilinx ISE projects targetting different board as follows

zx_spectrum_48k_papilio_VGA : for Papilio Pro with Arcade MegaWing.
Because the external DRAM of the Papilio Pro is not used and there is not enough
RAMB internal to the FPGA, this configuration of Spectrum only has 32K RAM.
To do so, and in order for the project to synthesize, in file ram.v change
reg [7:0] sram [0:32767]; to reg [7:0] sram [0:16387];

A PS2 keyboard is required.

zx_spectrum_48k_pipistrello_HDMI : for Pipistrello board using a Digilent PS2 PMOD.
This implements a full 48K Spectrum using internal FPGA RAMB and outputs the
video via HDMI port. A PS2 keyboard is required to be plugged into the PS2 PMOD.

zx_spectrum_48k_pipistrello_VGA : for Pipistrello board with an Arcade MegaWing.
This implements a full 48K Spectrum using internal FPGA RAMB and outputs the
video via the MegaWing VGA port. A PS2 keyboard is required.
