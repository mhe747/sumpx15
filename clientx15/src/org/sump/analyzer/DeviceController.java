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

import java.awt.Container;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JComponent;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JProgressBar;
import javax.swing.Timer;

// TODO: when the dialog is closed using the window decoration's close function, close() is not called

/**
 * GUI Component that allows the user to control the device and start captures.
 * <p>
 * Its modelled after JFileChooser and should allow for non-dialog implementations
 * making it somewhat reusable.
 * 
 * @version 0.3
 * @author Michael "Mr. Sump" Poppitz
 *
 */
public class DeviceController extends JComponent implements ActionListener, Runnable {
	public final static int ABORTED = 0;
	public final static int DATA_READ = 1;
	public boolean AutoCaptureMode;
	
	/**
	 * Constructs device controller component.
	 *
	 */
	public DeviceController() {
		super();
		setLayout(new GridLayout(17, 2, 5, 5));
		setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

		device = new Device();

		String[] ports = device.getPorts();
		portSelect = new JComboBox(ports);
		add(new JLabel("Analyzer Port:"));
		add(portSelect);
		
		String[] speeds = {
			"50MHz", "20MHz", "10MHz", "5MHz", "2MHz", "1MHz",
			"500kHz", "200kHz", "100kHz", "50kHz", "20kHz", "10kHz",
			"1kHz", "500Hz", "200Hz", "100Hz", "50Hz", "20Hz", "10Hz"
		};
		speedSelect = new JComboBox(speeds);
		speedSelect.addActionListener(this);
		add(new JLabel("Sampling Rate:"));
		add(speedSelect);
		
		String[] sizes = {
			"8K", "4K", "2K", "1K", "512", "256", "128", "64"
		};
		sizeSelect = new JComboBox(sizes);
		sizeSelect.setSelectedIndex(0);
		add(new JLabel("Recording Size:"));
		add(sizeSelect);
	
		progress = new JProgressBar(0, 100);
		add(new JLabel("Progress:"));
		add(progress);
		
		CaptureButton = new JButton("Capture");
		CaptureButton.addActionListener(this);
		add(CaptureButton);

		SendButton = new JButton("Send");
		SendButton.addActionListener(this);
		add(SendButton);

		JButton cancel = new JButton("Cancel");
		cancel.addActionListener(this);
		add(cancel);

		capturedData = null;
		timer = null;
		worker = null;
		status = ABORTED;
	}

	/**
	 * Internal method that initializes a dialog and add this component to it.
	 * @param frame owner of the dialog
	 */
	private void initDialog(JFrame frame) {
		// check if dialog exists with different owner and dispose if so
		if (dialog != null && dialog.getOwner() != frame) {
			dialog.dispose();
			dialog = null;
		}
		// if no valid dialog exists, create one
		if (dialog == null) {
			String modeStr;
			modeStr = "FuncDialog";
			dialog = new JDialog(frame, modeStr, true);
			dialog.getContentPane().add(this);
			dialog.pack();
		}
		// reset progress bar
		progress.setValue(0);
		
	}

	/**
	 * Return the device data of the last successful run.
	 * 
	 * @return device data
	 */
	public CapturedData getDeviceData() {
		return (capturedData);
	}

	/**
	 * Extracts integers from strings regardless of trailing trash.
	 * 
	 * @param s string to be parsed
	 * @return integer value, 0 if parsing fails
	 */
	private int smartParseInt(String s) {
		int val = 0;
	
		try {
			for (int i = 1; i <= s.length(); i++)
				val = Integer.parseInt(s.substring(0, i));
		} catch (NumberFormatException E) {}
		
		return (val);
	}

	/**
	 * Starts capturing from device or transmitting to device. Should not be called externally.
	 */
	public void run()  {
		String value = (String)portSelect.getSelectedItem();
		// TODO: need to check if attach was successful
		device.attach(value);
		
		value = (String)sizeSelect.getSelectedItem();
		int s = smartParseInt(value);
		if (value.indexOf("K") > 0)
			s *= 1024;
		System.out.println("Size: " + s);
		device.setSize(s);
		
		if (DAC_MODE==true) {
			  	if (externalCapturedData==null) {
			  		System.out.println("ERROR : No stored buffer in DAC mode.. will auto generate");
			  	}
			  	else {
			  		System.out.println("DeviceController in DAC mode and has stored buffer..");	
			  		// here we send samples to DAC
					try {

						System.out.println("DAC buffer has "+ externalCapturedData.triggerPosition + " samples");
						if (externalCapturedData.triggerPosition < s) {
							s = externalCapturedData.triggerPosition;
						}
						
						if (s < 8192) {
							System.out.println("send to BeagleSDR "+ s + " samples");
							
							// send the buffer
							device.writeSample(externalCapturedData.values, s);
							
							// complete the remained buffer to 8192 samples
							int rm =  8192 - s;
							int[] remain = new int[rm];
							for (int k = 0; k < rm; k++)
								remain[k] = 0;							
							device.writeSample(remain, 8192 - s);
						}							
						else {
							device.writeSample(externalCapturedData.values, 8192);
							//device.writeSample(integers, 8192);
							System.out.println("send to BeagleSDR 8k samples");
						}

					} catch (Exception ex) {
						// TODO: could make sense to also return half read captures if array length is corrected
						ex.printStackTrace(System.out);
					}			  		
			  	}
		}
		else {
			// here we capture samples from ADC
	  		try {
	  			capturedData = device.run();

	  		} catch (Exception ex) {
			// TODO: could make sense to also return half read captures if array length is corrected
				capturedData = null;
				ex.printStackTrace(System.out);
			}	

		}
		
		device.detach();

		status = DATA_READ;
	}
	
	/**
	 * Sets the enabled state of all trigger check boxes.
	 * @param enable <code>true</code> to enable all check boxes, <code>false</code> to disable them
	 */
	private void setTriggerEnabled(boolean enable) {
		for (int i = 0; i < 32; i++) {
			triggerMask[i].setEnabled(enable);
			triggerValue[i].setEnabled(enable);
		}
	}
	
	/**
	 * Sets the enabled state of all configuration components of the dialog.
	 * @param enable <code>true</code> to enable components, <code>false</code> to disable them
	 */
	private void setDialogEnabled(boolean enable,boolean enableSize,boolean enableRatio,boolean enableTrig) {
		portSelect.setEnabled(enable);
		speedSelect.setEnabled(enable);
		sizeSelect.setEnabled(enableSize);
/*		
		ratioSelect.setEnabled(enableRatio);
		triggerEnable.setEnabled(enableTrig);
*/
		if(DAC_MODE==false) {
			CaptureButton.setEnabled(true);
			SendButton.setEnabled(false);
/*			
			if (triggerEnable.isSelected() || !enableTrig)
				setTriggerEnabled(enable);
*/				
		}
		else {
			CaptureButton.setEnabled(false);
			SendButton.setEnabled(true);			
		}
	}

	/**
	 * Properly closes the dialog.
	 * This method makes sure timer and worker thread are stopped before the dialog is closed.
	 *
	 */
	private void close() {
		if (timer != null) {
			timer.stop();
			timer = null;
		}
		if (worker != null) {
			worker.interrupt();
			worker = null;
		}
		dialog.hide();
	}
	
	/**
	 * Starts the capture thread.
	 */
	private void startCapture() {
		try {
			setDialogEnabled(false,false,false,false);
			timer = new Timer(100, this);
			worker = new Thread(this);
			timer.start();
			worker.start();
			// here we should get data through UART
		} catch(Exception E) {
			E.printStackTrace(System.out);
		}
	}
	
	/**
	 * Starts the Send thread.
	 */
	private void startSend() {
		try {
			setDialogEnabled(false,false,false,false);
			timer = new Timer(100, this);
			worker = new Thread(this);
			timer.start();
			worker.start();
			// here we should send data through UART
		} catch(Exception E) {
			E.printStackTrace(System.out);
		}
	}	
	/**
	 * Handles all action events for this component.
	 */ 
	public void actionPerformed(ActionEvent event) {
		Object o = event.getSource();
		String l = event.getActionCommand();
		
		if (o == timer) {
			if (status == DATA_READ) {
				close();
			} else {
				if(device.isRunning())
					progress.setValue(device.getPercentage());
			}
		} else {
		
			if (o == triggerEnable) {
				boolean enable = false;
				if (triggerEnable.isSelected())
					enable = true;
				setTriggerEnabled(enable);
			} else if (o == speedSelect) {
				if (((String)speedSelect.getSelectedItem()).equals("50MHz"))
					filterEnable.setEnabled(false);
				else
					filterEnable.setEnabled(true);
			} else if (l.equals("Capture")) {
				System.out.println("Capture Thread");
				startCapture();
			} else if (l.equals("Send")) {
				System.out.println("Send Thread");
				startSend();
			}			
			else if (l.equals("Cancel")) {
				AutoCaptureMode = false;
				System.out.println("Stop Thread");
				device.detach();
				close();
			}
		}
	}
	
	/**
	 * Displays the device controller dialog with enabled configuration portion and waits for user input.
	 * 
	 * @param frame parent frame of this dialog
	 * @return status, which is either <code>ABORTED</code> or <code>DATA_READ</code>
	 * @throws Exception
	 */
	public int showCaptureDialog(JFrame frame) throws Exception {
		status = ABORTED;
		initDialog(frame);
		setDialogEnabled(true,true,true,true);
		dialog.show();
		return status;
	}

	public int showSendDialog(JFrame frame) throws Exception {
		status = ABORTED;
		initDialog(frame);
		setDialogEnabled(true,true,false,false);
		dialog.show();
		return status;
	}
	
	/**
	 * Displays the device controller dialog with disabled configuration, starting capture immediately.
	 * 
	 * @param frame parent frame of this dialog
	 * @return status, which is either <code>ABORTED</code> or <code>DATA_READ</code>
	 * @throws Exception
	 */
	public int showCaptureProgress(JFrame frame) throws Exception {
		status = ABORTED;
		initDialog(frame);
		startCapture();
		dialog.show();		
		return status;
	}

	private Thread worker;
	private Timer timer;
	
	private JComboBox portSelect;
	private JComboBox speedSelect;
	private JComboBox sizeSelect;
	private JComboBox ratioSelect;
	private JCheckBox filterEnable;
	private JCheckBox triggerEnable;
	private JCheckBox[] triggerMask;
	private JCheckBox[] triggerValue;
	private JProgressBar progress;
	private JButton CaptureButton;
	private JButton SendButton;
	
	private JDialog dialog;
	private Device device = null;
	private CapturedData capturedData = null;
	
	static public CapturedData externalCapturedData = null;
	static public boolean getExternalData = false;
	protected static boolean DAC_MODE; 
	
	private int status;
	
	private static final long serialVersionUID = 1L;

	public void startDAC() {
		DAC_MODE = true;	
	}

	public void startDAC(int m) {
		DAC_MODE = true;
		
		if (device!=null) {	        			
			try {				
				String value = (String)portSelect.getSelectedItem();
				device.attach(value);
				// write few samples to DAC memory
				device.writeSample(externalCapturedData.values, 8192);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		
	}
	
	public void stopDAC() {
		DAC_MODE = false;
	}
	
	
}
