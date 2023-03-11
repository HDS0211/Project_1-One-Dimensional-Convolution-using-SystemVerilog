# Project_1-One-Dimensional-Convolution-using-SystemVerilog

The objective of this project is to perform a simple one dimensional convolution(multiplication and addition) between two vectors. 
The idea behind performing a convolution operation is to demonstrate the working of a single layer of a Convolution Neural Network. 
The design utilizes memory and arithmeyic unit perform the operation. 

The Project is divided into three parts:

Part_1: A simple convolution operation is carried out between 8 bit input data and 4 bit mask. The properties of the rtl modules in part 1 is as follows:
	1. Two testbench files (Simple and Random Testbench) provided for testing
	2. Three hex files namely random_input_x, random_input_hex, expected_output_hex
	3. The next set includes the SystemVerilog files:
   		i.  conv_8_4.sv is the main top level code.
   		ii. datapath.sv, accumulator.sv, memory.sv forms theentire datapath of the design
   		iii.The remaining 6 files are the sv code files to implement the control logic
	4. The last file is this readme file

Part_2: In part 2, the design from part 1 is modified top perform a larger convolution with a 128bit input data and 32 bit mask. 
	This directory includes a total of 15 files.
	1. Two testbench files (Simple and Random Testbench) provided for testing
	2. Three hex files namely random_input_x, random_input_hex, expected_output_hex
	3. The next set includes the SystemVerilog files:
   		i.  conv_128_32.sv is the main top level code.
   		ii. datapath.sv, accumulator.sv, memory.sv forms theentire datapath of the design
   		iii.The remaining 6 files are the sv code files to implement the control logic
	4. The last file is this readme file

Part_3: In part 3, the design form part 2 is optimized to improve the speed. The directory structure is similar to parts 1 and 2. 

The Design in all the three parts was synthesized using Synopsys Design Compiler and the synthesis reports for all the 3 parts are included in a separate directory. 

Finally, a complete report for the entire project is generated which gives information of the timing, area and power.