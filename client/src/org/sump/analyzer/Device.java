/*
 *  Copyright (C) 2006 Michael Poppitz
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
 *
 */
package org.sump.analyzer;

import gnu.io.CommPortIdentifier;
import gnu.io.SerialPort;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;
import java.util.LinkedList;

/**
 * Device provides access to the physical logic analyzer device.
 * It requires the rxtx package from http://www.rxtx.org/ to
 * access the serial port the analyzer is connected to.
 * 
 * @version 0.3
 * @author Michael "Mr. Sump" Poppitz
 *
 */
public class Device extends Object {
	private final static int SET = 0x80;			// set register command 
	private final static int TRIGGER = 0x40;		// select trigger registers
	private final static int RUN = 0x20;			// arm trigger
	private final static int RESET = 0x10;		// reset
	private final static int REG0 = 0x02;		// select register 0
	private final static int REG1 = 0x04;		// select register 1
	private final static int REG2 = 0x08;		// select register 2

	private final static int FLAG_DEMUX = 0x00000001;	// demultiplex
	private final static int FLAG_FILTER = 0x00000002;	// noise filter

	private final static int CLOCK = 100000000;	// device clock in Hz
	
	/**
	 * Creates a device object.
	 *
	 */
	public Device() {
		triggerMask = 0;
		triggerValue = 0;
		triggerEnabled = false;
		filterEnabled = false;
		demux = false;
		divider = 0;
		stopCounter = 6400;
		readCounter = 12800;
		enabledGroups = new boolean[4];
		setEnabledChannels(-1); // enable all channels
			
		percentageDone = -1;
		
		port = null;
	}

	/**
	 * Sets the number of samples to obtain when started.
	 * 
	 * @param size number of samples, must be between 4 and 256*1024
	 */
	public void setSize(int size) {
		double ratio = (double)stopCounter / (double)readCounter;
		readCounter = size - 1;
		setRatio(ratio);
	}
	
	/**
	 * Sets the ratio for samples to read before and after started.
	 * @param ratio	value between 0 and 1; 0 means all before start, 1 all after
	 */
	public void setRatio(double ratio) {
		stopCounter = (int)(readCounter * ratio);
	}

	/**
	 * Set the sampling rate.
	 * All rates must be a divisor of 200.000.000.
	 * Other rates will be adjusted to a matching divisor.
	 * 
	 * @param rate		sampling rate in Hz
	 */
	public void setRate(int rate) {
		if (rate > CLOCK) {
			demux = true;
			divider = (2 * CLOCK / rate) - 1;
		} else {
			demux = false;
			divider = (CLOCK / rate) - 1;
		}
	}
	
	/**
	 * Configures the conditions that must be met to fire the trigger.
	 * <br>
	 * Each bit of the integer parameters represents one channel.
	 * <br>
	 * The LSB represents channel 0, the MSB channel 31.
	 * <p>
	 * To disable the trigger, set mask to 0. This will cause it to always fire.
	 * 
	 * @param mask bit map defining which channels to watch
	 * @param value bit map defining what value to wait for on watched channels
	 */
	public void setTrigger(int mask, int value) {
		triggerMask = mask;
		triggerValue = value;
	}
	
	/**
	 * Sets wheter or not to enable the trigger.
	 * @param enable <code>true</code> enables the trigger, <code>false</code> disables it.
	 */
	public void setTriggerEnabled(boolean enable) {
		triggerEnabled = enable;
	}

	/**
	 * Sets wheter or not to enable the noise filter.
	 * @param enable <code>true</code> enables the noise filter, <code>false</code> disables it.
	 */
	public void setFilterEnabled(boolean enable) {
		filterEnabled = enable;
	}

	/**
	 * Get the maximum sampling rate available.
	 * @return maximum sampling rate
	 */
	public int getMaximumRate() {
		return (2 * CLOCK);
	}

	/**
	 * Returns the current trigger mask.
	 * @return current trigger mask
	 */
	public int getTriggerMask() {
		return (triggerMask);
	}

	/**
	 * Returns the current trigger value.
	 * @return current trigger value
	 */
	public int getTriggerValue() {
		return (triggerValue);
	}
	
	/**
	 * Returns wether or not the trigger is enabled.
	 * @return <code>true</code> when trigger is enabled, <code>false</code> otherwise
	 */
	public boolean isTriggerEnabled() {
		return (triggerEnabled);
	}

	/**
	 * Returns wether or not the noise filter is enabled.
	 * @return <code>true</code> when noise filter is enabled, <code>false</code> otherwise
	 */
	public boolean isFilterEnabled() {
		return (filterEnabled);
	}

	/**
	 * Returns wether or not the device is currently running.
	 * It is running, when another thread is inside the run() method reading data from the serial port.
	 * @return <code>true</code> when running, <code>false</code> otherwise
	 */
	public boolean isRunning() {
		return (percentageDone != -1);
	}

	/**
	 * Returns the percentage of the expected data that has already been read.
	 * The return value is only valid when <code>isRunning()</code> returns <code>true</code>. 
	 * @return percentage already read (0-100)
	 */
	public int getPercentage() {
		return (percentageDone);
	}

	/**
	 * Gets a string array containing the names all available serial ports.
	 * @return array containing serial port names
	 */
	public String[] getPorts() {
		Enumeration portIdentifiers = CommPortIdentifier.getPortIdentifiers();
		LinkedList portList = new LinkedList();
		CommPortIdentifier portId = null;

		while (portIdentifiers.hasMoreElements()) {
			portId = (CommPortIdentifier) portIdentifiers.nextElement();
			if (portId.getPortType() == CommPortIdentifier.PORT_SERIAL) {
				portList.addLast(portId.getName());
				System.out.println(portId.getName());
			}
		}
			
		return ((String[])portList.toArray(new String[1]));
	}

	/**
	 * Attaches the given serial port to the device object.
	 * The method will try to open the port.
	 * <p>
	 * A return value of <code>true</code> does not guarantee that a
	 * logic analyzer is actually attached to the port.
	 * <p>
	 * If the device is already attached to a port this port will be
	 * detached automatically. It is therefore not necessary to manually
	 * call <code>detach()</code> before reattaching.
	 *
	 * @param portName		the name of the port to open
	 * @return				<code>true</code> when the port has been assigned successfully;
	 * 						<code>false</code> otherwise.
	 */
	public boolean attach(String portName) {
		Enumeration portList = CommPortIdentifier.getPortIdentifiers();
		CommPortIdentifier portId = null;
		boolean found = false;

		try {
			detach();
	
			while (!found && portList.hasMoreElements()) {
				portId = (CommPortIdentifier) portList.nextElement();
	
				if (portId.getPortType() == CommPortIdentifier.PORT_SERIAL) {
					if (portId.getName().equals(portName)) {
						found = true;
					}
				}
			}
			
			if (found) {
				port = (SerialPort) portId.open("Logic Analyzer Client", 1000);
				
				port.setSerialPortParams(
					115200, /*115200, 460800, 921600*/
					SerialPort.DATABITS_8,
					SerialPort.STOPBITS_1,
					SerialPort.PARITY_NONE
				);
				port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
				port.disableReceiveFraming();
			}
		} catch(Exception E) {
			E.printStackTrace(System.out);
			return (false);
		}		
		return (found);
	}
	
	/**
	 * Detaches the currently attached port, if one exists.
	 * This will close the serial port.
	 *
	 */
	public void detach() {
		if (port != null)
				port.close();
	}
	
	/**
	 * Sends a command to the given stream.
	 * 
	 * @param output	stream to write command to
	 * @param opcode	one byte operation code
	 * @param data		four byte data portion
	 * @throws IOException if writing to stream fails
	 */
	private void sendCommand(OutputStream output, int opcode, int data) throws IOException {
		byte[] raw = new byte[5];
		int mask = 0xff;
		int shift = 0;
		
		raw[0] = (byte)(opcode | 0x01);
		for (int i = 1; i < 5; i++) {
			raw[i] = (byte)((data & mask) >> shift);
			mask = mask << 8;
			shift += 8;
		}

		String debugCmd = "";
		for (int j = 0; j < 5; j++) {
			for (int i = 7; i >= 0; i--) {
				if ((raw[j] & (1 << i)) != 0)
					debugCmd += "1";
				else
					debugCmd += "0";
			}
			debugCmd += " ";
		}
		System.out.println(debugCmd);
		
		output.write(raw);
	}
	
	/**
	 * Reads <code>channels</code> / 8 bytes from stream and compiles them into a single integer.
	 * 
	 * @param input stream to read from
	 * @param channels number of channels to read (must be multiple of 8)
	 * @return	integer containing four bytes read
	 * @throws IOException if stream reading fails
	 */
	private int readSample(InputStream input, int channels) throws IOException {
		int value = 0;

		for (int i = 0; i < channels / 8; i++){
			value |= input.read() << (8 * i);
		}

		return (value);
	}

	/**
	 * Reads <code>channels</code> / 8 bytes from stream and compiles them into a single integer.
	 * 
	 * @param output stream to write to
	 * @param channels number of channels to write (must be multiple of 8)
	 * @return	integer containing four bytes write
	 * @throws IOException if stream reading fails
	 */
	private int writeSample(OutputStream output, int nb_of_data) throws IOException {
		int value = 0;

		/* TODO : IMPLEMENTATION */

		return (value);
	}	
	/**
	 * Sends the configuration to the device, starts it, reads the captured data
	 * and returns a CapturedData object containing the data read as well as device configuration information.
	 * @return captured data
	 * @throws IOException when writing to or reading from device fails
	 */
	public CapturedData run() throws IOException {
		OutputStream outputStream = port.getOutputStream();
		InputStream inputStream = port.getInputStream();

		sendCommand(outputStream, RESET, 0);
		if (triggerEnabled) {
			sendCommand(outputStream, SET | TRIGGER | REG0, triggerMask);
			sendCommand(outputStream, SET | TRIGGER | REG1, triggerValue);
		} else {
			sendCommand(outputStream, SET | TRIGGER | REG0, 0);
			sendCommand(outputStream, SET | TRIGGER | REG1, 0);
		}
		sendCommand(outputStream, SET | REG0, divider);
		if (demux) {
			sendCommand(outputStream, SET | REG2, FLAG_DEMUX);
			sendCommand(outputStream, SET | RUN | REG1, ((stopCounter & 0x7fff8) << 13) | ((readCounter & 0x7fff8) >> 3));
		} else {
			if (filterEnabled)
				sendCommand(outputStream, SET | REG2, FLAG_FILTER);
			else 
				sendCommand(outputStream, SET | REG2, 0);
			sendCommand(outputStream, SET | RUN | REG1, ((stopCounter & 0x3fffc) << 14) | ((readCounter & 0x3fffc) >> 2));
		}
		// due to the vhdl design the first sample is currently garbage
		readSample(inputStream, 32);

		// check if data needs to be multiplexed
		int channels;
		int samples;
		if (demux) {
			channels = 16;
			samples = (readCounter & 0x7fff8);
		} else {
			channels = 32;
			samples = (readCounter & 0x3fffc);
		}
		int[] buffer = new int[samples];
		for (int i = samples - 1; i >= 0; i--) {
			buffer[i] = readSample(inputStream, channels);
			//14 bits DAC
			buffer[i] &= 0x3FFF;
			/* filter */
			if (i < (samples - 6)) {
				buffer[i] += buffer[i+1] + buffer[i+2] + buffer[i+3] + buffer[i+4] + buffer[i+5] ;
				buffer[i] /= 6;
			}
			
			percentageDone = 100 - (100 * i) / buffer.length;
		}

		inputStream.close();
		outputStream.close();
		percentageDone = -1;

		int pos = readCounter - stopCounter - 4 / (divider + 1); // 3 cycles for the device to get started
		int rate = demux?2*CLOCK / (divider + 1):CLOCK / (divider + 1);
		return (new CapturedData(buffer, pos, rate, channels, enabledChannels));
	}
	
	/**
	 * Sends the configuration to the device, starts it, reads the captured data
	 * and returns a CapturedData object containing the data read as well as device configuration information.
	 * @return captured data
	 * @throws IOException when writing to or reading from device fails
	 */
	public void send() throws IOException {
		OutputStream outputStream = port.getOutputStream();
		InputStream inputStream = port.getInputStream();

		sendCommand(outputStream, RESET, 0);

		sendCommand(outputStream, SET | REG0, divider);

		// check if data needs to be multiplexed
		/* TODO : IMPLEMENTATION */
	}
	
	/**
	 * Set enabled channels.
	 * @param mask bit map defining enabled channels
	 */
	public void setEnabledChannels(int mask) {
		enabledChannels = mask;
		// determine enabled groups
		for (int i = 0; i < 4; i++)
			enabledGroups[i] = ((enabledChannels  >> (8 * i)) & 0xff) > 0;
	}

	
	private SerialPort port;
	
	private int percentageDone;
	
	private boolean demux;
	private boolean filterEnabled;
	private boolean triggerEnabled;
	private int triggerMask;
	private int triggerValue;
	private int enabledChannels;
	private int divider;
	private int stopCounter;
	private int readCounter;
	private boolean enabledGroups[];
	

}
