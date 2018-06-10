# SUMPx15
.. Ported to BeagleSDR project FPGA Based Logic Analyzer With 80 Mhz ADC input and 125 Mhz DAC output
## 2006 Initial revision in www.sump.org
## 2018 SUMPx15 Project started here.
        https://github.com/mhe747/sumpx15
        http://sump.org/projects/analyzer/
    

How to start :

SumpX15 works at frequency of 50 Mhz. Tested with Tektronix TDS 210 2 channel 60 Mhz 1GS/s oscilloscope.
All data are sent through UART at speed of 115200 bps.
First you need to compile a .bit file to be loaded into BeagleSDR's FPGA, there is a xilinx spartan 3s500e.
Use Xilinx ISE 14.7 to open the project file in sumpx15/fpgax15/WaveGenerator.xise 
which contains all verilog files and la.ucf that need to be compiled, generate the bit file.
Load the .bit into FPGA with Xilinx Impact. Now all done...

Leave Xilinx ISE, start Eclipse to edit and compile the Java app project.
Then, click sumpx15/clientx15/Makefile.bat which require java compiler in Java 1.8 JDK,
all java sources are compiled in "/bin" directory, go to "/bin" directory, click run.bat
The Java control app. would be launched, otherwise you have to check your bin directory and Java installation.

Once the app launches ..

the DAC used 14 bits, in a 8192 samples buffer 

	1)
	now click to "blue hadoken" icon in menu icon bar
	a popup window opens, now click on "decimal" radio button at top right side of the popup
	in the central edit box put some values between 0 to 16383, eg. 16383 16383 16383 0 0 0 0 0 0
	you notice that you can also put hexadecimal values, this feature remains superfluous since one unlikely use hexadecimal values.
	set a numerical value in edit box near "Time :" (let's says 1024)
	click "memory", then waveforms should now be generated and showed in chronogram window
	click to red cycle icon to transmit the buffer to BeagleSDR's FPGA memory
	use an oscilloscope to check the DAC SMA connector (Ant Tx), yes you should have some periodical waves now

the ADC used 8 bits, in a 8192 samples buffer

	2) 
	to use the original sump fpga oscilloscope feature, click to "red yellow rocket" icon button
	click to capture of the popup window to start one time probing thread
	if you want to have the automatic cyclic probing (every second), click to green cycle button
	click to capture of the popup to start probing thread, click to cancel to stop the thread
	once stopped, click to "spectrum view" radio button to activate the spectrum analyze mode
	click to magnifying glass minus to have all span of frequencies. 

remember that the FPGA part had completely been changed from original SUMP, only the Java app client looks similar.

