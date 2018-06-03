
++ COMPILE FROM JAVA ECLIPSE
1) The software has been successfully tested on Eclipse Oxygen platform (http://www.eclipse.org/downloads/eclipse-packages/)

2) To build the software, make sure all the external libraries are correctly linked and visible (rxtx-2.x.x.jar, RXTXcomm.jar rxtxSerial.dll)

3) To enable the connection with external serial port devices, check the instruction 
     controller = new ADCController(); in MainWindow.java. 



++ INSERT VALUES INTEGER FROM NEW GUI WINDOW TO MEMORY
1) Open "Project" menu link and select "Import from window" action

2) A new gui will be displayed on the center of the screen. In the GUI there is a text area where you can write the sequence of integers (the integer values must be separated by one space)

3) Select number of times the sequence should be repeated
  
4) After writing the sequence of integer hexadecimal numbers, press to Memory button make the sequence appear as signal wave on the main window as logical bit wave.
   Everytime you change the sequence, press save to refresh the wave on the main window



++ TO WRITE TO DAC
Once the memory is has been filled with new inserted custom values
1) Press the Red/Black cycle icon

2) Click to square icon near the Red/Black cycle icon to erase DAC memory



++ TO READ FROM ADC
1) Press the Red yellow rocket icon, click on Capture button

2) Press the Green/Black cycle icon to have a cyclic periodic 1 second of reading

3) Click to Cancel button to stop continuous reading



++ TO READ SLA FILE
1) Open "File" menu link and select "Open..." action

2) select the SLA file to be displayed (an example is is the test_16k.sla file in the root software directory)

3) On the main window the values reported in SLA file are displayed as logical bit wave.