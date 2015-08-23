@echo off
REM generate VHDL source from ZX Spectrum binary ROM file
romgen tc2048.rom ROM_CPU 14 l r e > ROM_CPU.vhd
