BE CAREFUL

1) The software has been successfully tested on Eclipse Oxygen platform (http://www.eclipse.org/downloads/eclipse-packages/)

2) To build the software, make sure all the external libraries are correctly linked and visible (rxtx-2.1.7.jar, RXTXcomm.jar rxtxSerial.dll)

3) To enable the connection with external serial port devices, uncomment the instruction 
     controller = new ADCController(); in MainWindow.java. 
   
INSERT VALUES INTEGER FROM NEW GUI WINDOW

1) Open "Project" menu link and select "Import from window" action

2) A new gui will be displayed on the center of the screen. In the GUI there is a text area where you can write the sequence 
   of integers (the integer values must be separated by one blank); at the beginning the sequence 1 2 3 4 5 6 is reported
   
3) After writing the sequence of integer numbers, press save to make the sequence appear on the main window as logical bit wave.
   Everytime you change the sequence, press save to refresh the wave on the main window
   
READ SLA FILE

1) Open "File" menu link and select "Open..." action

2) select the SLA file to be displayed (an example is is the test_16k.sla file in the root software directory)

3) On the main window the values reported in SLA file are displayed as logical bit wave.