cd bin
jar xf ../lib/RXTXcomm.jar
jar cfm analyzer.jar Manifest.txt org gnu
if not exist rxtxSerial.dll copy ..\lib\rxtxSerial.dll .
java -Djava.library.path=. -jar analyzer.jar
