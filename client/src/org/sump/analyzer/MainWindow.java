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

import java.awt.BorderLayout;
import java.awt.Checkbox;
import java.awt.CheckboxGroup;
import java.awt.Color;
import java.awt.Container;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import javax.swing.BorderFactory;
import javax.swing.ButtonGroup;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JScrollPane;
import javax.swing.JSeparator;
import javax.swing.JTextArea;
import javax.swing.JToolBar;
import javax.swing.border.Border;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.filechooser.FileFilter;

import org.sump.analyzer.tools.Tool;

/**
 * Main frame and starter for Logic Analyzer Client.
 * <p>
 * This class only provides a simple end-user frontend and no functionality to be used by other code.
 * 
 * @version 0.7
 * @author Michael "Mr. Sump" Poppitz
 */
public final class MainWindow extends WindowAdapter implements Runnable, ActionListener, WindowListener, StatusChangeListener {

	/**
	 * Creates a JMenu containing items as specified.
	 * If an item name is empty, a separator will be added in its place.
	 * 
	 * @param name Menu name
	 * @param entries array of menu item names.
	 * @return created menu
	 */
	private JMenu createMenu(String name, String[] entries) {
		JMenu menu = new JMenu(name);
		for (int i = 0; i < entries.length; i++) {
			if (!entries[i].equals("")) {
				JMenuItem item = new JMenuItem(entries[i]);
				item.addActionListener(this);
				menu.add(item);
			} else {
				menu.add(new JSeparator());
			}
		}
		return (menu);
	}
	
	/**
	 * Creates tool icons and adds them the the given tool bar.
	 * 
	 * @param tools tool bar to add icons to
	 * @param files array of icon file names
	 * @param descriptions array of icon descriptions
	 */
	private void createTools(JToolBar tools, String[] files, String[] descriptions) {
		for (int i = 0; i < files.length; i++) {
			URL u = MainWindow.class.getResource("icons/" + files[i]);
			JButton b = new JButton(new ImageIcon(u, descriptions[i]));
			b.setMargin(new Insets(0,0,0,0));
			b.addActionListener(this);
			tools.add(b);
		}
	}
	
	// ?new2 init
	/**
	 * Creates switches adds them the the given tool bar.
	 * 
	 * @param tools tool bar to add icons to
	 * @param files array of icon file names
	 * @param descriptions array of icon descriptions
	 */
	private void createSwitches1(JToolBar tools) {
		 waveViewEnabled.setSelected(true);
		 ButtonGroup analogGrp = new ButtonGroup();
		 analogGrp.add(waveViewEnabled);
		 analogGrp.add(spectrumViewEnabled);
		 tools.add(waveViewEnabled);
		 tools.add(spectrumViewEnabled);
	}
	// ?new2 end
	
	
	
	

	/**
	 * Enables or disables functions that can only operate when captured data has been added to the diagram.
	 * @param enable set <code>true</code> to enable these functions, <code>false</code> to disable them
	 */
	private void enableDataDependingFunctions(boolean enable) {
		diagramMenu.setEnabled(enable);
		toolMenu.setEnabled(enable);
	}
	
	/**
	 * Inner class defining a File Filter for SLA files.
	 * 
	 * @author Michael "Mr. Sump" Poppitz
	 *
	 */
	private class SLAFilter extends FileFilter {
		public boolean accept(File f) {
			return (f.isDirectory() || f.getName().toLowerCase().endsWith(".sla"));
		}
		public String getDescription() {
			return ("Sump's Logic Analyzer Files (*.sla)");
		}
	}

	/**
	 * Inner class defining a File Filter for SLP files.
	 * 
	 * @author Michael "Mr. Sump" Poppitz
	 *
	 */
	private class SLPFilter extends FileFilter {
		public boolean accept(File f) {
			return (f.isDirectory() || f.getName().toLowerCase().endsWith(".slp"));
		}
		public String getDescription() {
			return ("Sump's Logic Analyzer Project Files (*.slp)");
		}
	}
	
	/**
	 * Default constructor.
	 *
	 */
	public MainWindow() {
		super();
		project = new Project();
	}
	
	/**
	 * Creates the GUI.
	 *
	 */
	void createGUI() {

		frame = new JFrame("Logic Analyzer Client");
		frame.setIconImage((new ImageIcon("org/sump/analyzer/icons/la.png")).getImage());
		Container contentPane = frame.getContentPane();
		contentPane.setLayout(new BorderLayout());

		JMenuBar mb = new JMenuBar();
		
		// file menu
		String[] fileEntries = {"Open...", "Save as...", "", "Exit"};
		JMenu fileMenu = createMenu("File", fileEntries);
		mb.add(fileMenu);

		// project menu
		String[] projectEntries = {"Open Project...", "Save Project as...", "Import from window..." };
		JMenu projectMenu = createMenu("Project", projectEntries);
		mb.add(projectMenu);

		// device menu
		String[] deviceEntries = {"Capture...", "Repeat Capture"};
		JMenu deviceMenu = createMenu("Device", deviceEntries);
		mb.add(deviceMenu);
		
		// diagram menu
		String[] diagramEntries = {"Zoom In", "Zoom Out", "Default Zoom", "", "Diagram Settings...", "Labels..."};
		diagramMenu = createMenu("Diagram", diagramEntries);
		mb.add(diagramMenu);

		// tools menu
		String[] toolClasses = { 	// TODO: should be read from properties
				"org.sump.analyzer.tools.StateAnalysis",
				"org.sump.analyzer.tools.SPIProtocolAnalysis",
				"org.sump.analyzer.tools.I2CProtocolAnalysis"
		};
		List loadedTools = new LinkedList();
		for (int i = 0; i < toolClasses.length; i++) {
			try {
				Class tool = Class.forName(toolClasses[i]);
				Object o = tool.newInstance();
				if (o instanceof Tool)
					loadedTools.add(o);
				if (o instanceof Configurable)
					project.addConfigurable((Configurable)o);
			} catch (Exception e) { e.printStackTrace(); }
		}

		tools = new Tool[loadedTools.size()];
		Iterator test = loadedTools.iterator();
		for (int i = 0; test.hasNext(); i++)
			tools[i] = (Tool)test.next();

		String[] toolEntries = new String[tools.length];
		for (int i = 0; i < tools.length; i++) {
			tools[i].init(frame);
			toolEntries[i] = tools[i].getName();
		}

		toolMenu = createMenu("Tools", toolEntries);
		mb.add(toolMenu);

		// help menu
		String[] helpEntries = {"About"};
		JMenu helpMenu = createMenu("Help", helpEntries);
		mb.add(helpMenu);

		frame.setJMenuBar(mb);
		
		JToolBar tools = new JToolBar();
		tools.setRollover(true);
		tools.setFloatable(false);
		
		String[] fileToolsF = {"fileopen.png", "filesaveas.png", "gbf.png", "wavebox.png", "activate.png", "deactivate.png"}; // , "fileclose.png"};
		String[] fileToolsD = {"Open...", "Save as...", "Import from window...", "Define function...","Activate...", "Deactivate..."}; // , "Close"};
		createTools(tools, fileToolsF, fileToolsD);
		tools.addSeparator();

		String[] deviceToolsF = {"launch.png", "reload.png"};
		String[] deviceToolsD = {"Capture...", "Repeat Capture"};
		createTools(tools, deviceToolsF, deviceToolsD);
		tools.addSeparator();

		String[] diagramToolsF = {"viewmag+.png", "viewmag-.png", "viewmag1.png"};
		String[] diagramToolsD = {"Zoom In", "Zoom Out", "Default Zoom"};
		createTools(tools, diagramToolsF, diagramToolsD);
		tools.addSeparator();
		
        createSwitches1(tools);    // ?new2
		tools.addSeparator();      // ?new2
		
	
		
		contentPane.add(tools, BorderLayout.NORTH);
		
		status = new JLabel(" ");
		contentPane.add(status, BorderLayout.SOUTH);
		
		diagram = new Diagram();
		project.addConfigurable(diagram);
		diagram.addStatusChangeListener(this);
		contentPane.add(new JScrollPane(diagram), BorderLayout.CENTER);

		enableDataDependingFunctions(false);

		frame.setSize(1000, 835);
		frame.addWindowListener(this);
		frame.setVisible(true);

		fileChooser = new JFileChooser();
		fileChooser.addChoosableFileFilter((FileFilter) new SLAFilter());

		projectChooser = new JFileChooser();
		projectChooser.addChoosableFileFilter((FileFilter) new SLPFilter());
		
		adc_controller = new DeviceController();
		dac_controller = new DACController();
		//project.addConfigurable(controller);

	}
	
	/**
	 * Handles all user interaction.
	 */
	public void actionPerformed(ActionEvent event) {
		String label = event.getActionCommand();
		// if no action command, check if button and if so, use icon description as action
		if (label.equals("")) {
			if (event.getSource() instanceof JButton)
				label = ((ImageIcon)((JButton)event.getSource()).getIcon()).getDescription();
		}
		System.out.println(label);
		try {
			
			if (label.equals("Open...")) {
				if (fileChooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = fileChooser.getSelectedFile();
					if (file.isFile())
						loadData(file);
				}
			
			} else if (label.equals("Save as...")) {
				if (fileChooser.showSaveDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = fileChooser.getSelectedFile();
					System.out.println("Saving: " + file.getName() + ".");
					diagram.getCapturedData().writeToFile(file);
				}

			} else if (label.equals("Open Project...")) {
				if (projectChooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = projectChooser.getSelectedFile();
					if (file.isFile())
						loadProject(file);
				}
				
			} else if (label.equals("Save Project as...")) {
				if (projectChooser.showSaveDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = projectChooser.getSelectedFile();
					System.out.println("Saving Project: " + file.getName() + ".");
					project.store(file);
				}
			
			}else if (label.equals("Import from window...")) {
				
				JFrame f = new JFrame("Import from window");
				
				 Container content = f.getContentPane();
				 
				 content.setLayout(new GridBagLayout());
				 GridBagConstraints c = new GridBagConstraints();
				 
				 JLabel lb = new JLabel("write integer values separated by blank");
				 ButtonGroup formatGrp = new ButtonGroup();
				 JRadioButton  hex = new JRadioButton ("hexadecimal");
				 hex.setSelected(true);
				 JRadioButton  decimal = new JRadioButton ("decimal");
				 formatGrp.add(hex);
				 formatGrp.add(decimal);
				 errorLabel.setVisible(false);
				 errorLabel.setText("ERROR: invalid");
				 errorLabel.setForeground(new Color(255,0,0));
	             JTextArea ta = new JTextArea(15,20);
				 ta.setText("1 1  10 10 2000 2000 1000 1000 2000 2000 3500 3500 4000 4000 3500 3500 2000 2000 1000 1000  2000 2000 10 10 1 1");
				 ta.setLineWrap(true);
				 ta.setWrapStyleWord(true);
				 

				 
				 
				 JButton drawBtn = new JButton("Draw");
				 JButton closeBtn = new JButton("Close");
					//ta.setBounds(0,0, 20, 20);
				 
				 
					
				 c.insets = new Insets(10,10,0,0);  //top padding
				 c.anchor = GridBagConstraints.NORTHWEST;
				// c.weightx = 1.0;
				 c.weighty = 0;
				
				 //c.insets = new Insets(0,10,0,10);  
				 //   c.fill = GridBagConstraints.HORIZONTAL;
				    c.gridx = 0;
				    c.gridy = 0;
				    //c.ipadx = 50;
				    //c.ipady = 50;
				    content.add(lb, c);
				 
				 GridBagConstraints c1 = new GridBagConstraints();
				 c1.anchor = GridBagConstraints.NORTHWEST;
				 c1.insets = new Insets(10,10,0,0);  //top padding
				 c1.gridx = 1;
				 c1.gridy = 0;
				 content.add(hex, c1);
				 c1.anchor = GridBagConstraints.NORTHEAST;
				 content.add(decimal, c1);
				 
				 c.weighty = 0;
					
				 //c.insets = new Insets(0,10,0,10);  
				 //   c.fill = GridBagConstraints.HORIZONTAL;
		         c.gridx = 0;
		         c.gridy = 1;
				    //c.ipadx = 50;
				    //c.ipady = 50;
			     content.add(errorLabel, c); 
				
				 
				 c.gridwidth = 2;
				 c.weighty = 0.5;
				    c.fill = GridBagConstraints.HORIZONTAL;
				    c.gridx = 0;
				    c.gridy = 2;
				    c.gridheight = 1;
				    c.ipady = 80;
				    c.ipady = 300;
				    content.add(new JScrollPane(ta), c);
				    
				    GridBagConstraints c2 = new GridBagConstraints();
				    c2.anchor = GridBagConstraints.NORTHWEST;
				    c2.insets = new Insets(10,10,10,0);  //top padding
				    c2.weightx = 0.1;
				    c.fill = GridBagConstraints.NONE;
				   
				    c.ipady = 0;
				    c.ipady = 0;
				   
				    c.ipady = 0;
				   // c.gridwidth = 1;
				    //c.fill = GridBagConstraints.LAST_LINE_START;
				    c2.gridx = 0;
				    c2.gridy = 3;
				    content.add(drawBtn, c2);
				    
				   // c.weightx = 0.2;
				   
				   // c.fill = GridBagConstraints.LAST_LINE_START;
				    c2.gridx = 1;
				    c2.gridy = 3;
				    c2.insets = new Insets(10,0,10,0);  //top padding
				    //c2.weightx = 0.8;
				    content.add(closeBtn, c2);
				    
				    drawBtn.addActionListener(new ActionListener() {
				        public void actionPerformed(ActionEvent e)
				        {
				        	errorLabel.setVisible(false);
				            //System.out.print(ta.getText());
				            String[] integerStr = ta.getText().split(" ");
				            //System.out.println(integerStr.toString());
				            
				            int[] integersTmp = new int[integerStr.length];
				           
				            int validIndex = 0;
				            for(int i=0; i<integerStr.length; ++i)
				            {
				                integerStr[i].replace(" ", "");
				            	if(!integerStr[i].equals(""))
				            	{
				                	//integers[i] =Integer.parseInt(integerStr[i].replace(" ", ""));
				            		 try {
						            		integersTmp[validIndex] =  hex.isSelected() ? Integer.parseInt(integerStr[i], 16) : Integer.parseInt(integerStr[i], 10);
						            	}
						        		catch(java.lang.NumberFormatException ex)
						        		{
						        			errorLabel.setVisible(true);
						        			errorLabel.setText("ERROR (invalid input) " + ex.getMessage());
						        			return;
						        		}
						            	if( (integersTmp[validIndex] <0) || (integersTmp[validIndex] >Diagram.maxIntegerInput))  
						            	{
						            		errorLabel.setVisible(true);
						            		errorLabel.setText("ERROR (input out of valid range) " + integerStr[i]);
						        			return;
						            	}
				            	    ++validIndex;
				            	}
				            }
				            
				       
				           
				            int[] integers = new int[validIndex];
				            for(int i=0; i<validIndex; ++i)
				            	integers[i] = integersTmp[i];
				            
				            diagram.setCapturedData(new CapturedData(integers, integers.length,200000000,16,-4));
				           
				            
				        }
				    });
				    
				    closeBtn.addActionListener(new ActionListener() {
				        public void actionPerformed(ActionEvent e)
				        {
				        	f.dispose();
				        }
				    });
				    
				    
				 
				
				f.setSize(500,400);
				f.setLocationRelativeTo(null); 
				f.setVisible(true);
			
			}else if(label.equals("Define function...")) {
				
				JFrame f = new JFrame("Wavebox");
				
				 Container content = f.getContentPane();
				 
				 content.setLayout(new GridBagLayout());
				 GridBagConstraints c = new GridBagConstraints();
				 
				 JLabel lb = new JLabel("write integer values separated by blank");
				 ButtonGroup formatGrp = new ButtonGroup();
				 JRadioButton  hex = new JRadioButton ("hexadecimal");
				 hex.setSelected(true);
				 JRadioButton  decimal = new JRadioButton ("decimal");
				 formatGrp.add(hex);
				 formatGrp.add(decimal);
				 errorLabel.setVisible(false);
				 errorLabel.setText("ERROR: invalid");
				 errorLabel.setForeground(new Color(255,0,0));
	             JTextArea ta = new JTextArea(15,20);
				 ta.setText("");
				 ta.setLineWrap(true);
				 ta.setWrapStyleWord(true);
				 

				 
				 
				 JButton sendBtn = new JButton("Send");
				 JButton closeBtn = new JButton("Close");
					//ta.setBounds(0,0, 20, 20);
				 
				 
					
				 c.insets = new Insets(10,10,0,0);  //top padding
				 c.anchor = GridBagConstraints.NORTHWEST;
				// c.weightx = 1.0;
				 c.weighty = 0;
				
				 //c.insets = new Insets(0,10,0,10);  
				 //   c.fill = GridBagConstraints.HORIZONTAL;
				    c.gridx = 0;
				    c.gridy = 0;
				    //c.ipadx = 50;
				    //c.ipady = 50;
				    content.add(lb, c);
				 
				 GridBagConstraints c1 = new GridBagConstraints();
				 c1.anchor = GridBagConstraints.NORTHWEST;
				 c1.insets = new Insets(10,10,0,0);  //top padding
				 c1.gridx = 1;
				 c1.gridy = 0;
				 content.add(hex, c1);
				 c1.anchor = GridBagConstraints.NORTHEAST;
				 content.add(decimal, c1);
				 
				 c.weighty = 0;
					
				 //c.insets = new Insets(0,10,0,10);  
				 //   c.fill = GridBagConstraints.HORIZONTAL;
		         c.gridx = 0;
		         c.gridy = 1;
				    //c.ipadx = 50;
				    //c.ipady = 50;
			     content.add(errorLabel, c); 
				
				 
				 c.gridwidth = 2;
				 c.weighty = 0.5;
				    c.fill = GridBagConstraints.HORIZONTAL;
				    c.gridx = 0;
				    c.gridy = 2;
				    c.gridheight = 1;
				    c.ipady = 80;
				    c.ipady = 300;
				    content.add(new JScrollPane(ta), c);
				    
				    GridBagConstraints c2 = new GridBagConstraints();
				    c2.anchor = GridBagConstraints.NORTHWEST;
				    c2.insets = new Insets(10,10,10,0);  //top padding
				    c2.weightx = 0.1;
				    
				   // c.gridwidth = 1;
				    //c.fill = GridBagConstraints.LAST_LINE_START;
				    c2.gridx = 0;
				    c2.gridy = 3;
				    content.add(sendBtn, c2);
				    
				    JLabel timesLabel = new JLabel();
				    timesLabel.setText("Times:");
				    c2.anchor = GridBagConstraints.CENTER;
				    content.add(timesLabel, c2);
				    
				    
				    JTextArea ta2 = new JTextArea(10,10);
				    ta2.setText("1");
				    ta2.setLineWrap(true);
					ta2.setWrapStyleWord(true);
					ta2.setBorder(BorderFactory.createLineBorder(Color.BLACK));
					
				    c2.anchor = GridBagConstraints.EAST;
				   
				    content.add(ta2, c2);
				    
				   // c.weightx = 0.2;
				   
				   // c.fill = GridBagConstraints.LAST_LINE_START;
				    c2.gridx = 1;
				    c2.gridy = 3;
				    c2.anchor = GridBagConstraints.CENTER;
				    c2.insets = new Insets(10,0,10,0); 
				    //c2.weightx = 0.8;
				    content.add(closeBtn, c2);
				    
				    sendBtn.addActionListener(new ActionListener() {
				        public void actionPerformed(ActionEvent e)
				        {
				        	errorLabel.setVisible(false);
				            //System.out.print(ta.getText());
				            String[] integerStr = ta.getText().split(" ");
				            //System.out.println(integerStr.toString());
				            
				            int[] integersTmp = new int[integerStr.length];
				           
				            int validIndex = 0;
				            for(int i=0; i<integerStr.length; ++i)
				            {
				                integerStr[i].replace(" ", "");
				            	if(!integerStr[i].equals(""))
				            	{
				                	//integers[i] =Integer.parseInt(integerStr[i].replace(" ", ""));
				            		 try {
						            		integersTmp[validIndex] =  hex.isSelected() ? Integer.parseInt(integerStr[i], 16) : Integer.parseInt(integerStr[i], 10);
						            	}
						        		catch(java.lang.NumberFormatException ex)
						        		{
						        			errorLabel.setVisible(true);
						        			errorLabel.setText("ERROR (invalid input) " + ex.getMessage());
						        			return;
						        		}
						            	if( (integersTmp[validIndex] <0) || (integersTmp[validIndex] >Diagram.maxIntegerInput))  
						            	{
						            		errorLabel.setVisible(true);
						            		errorLabel.setText("ERROR (input out of valid range) " + integerStr[i]);
						        			return;
						            	}
				            	    ++validIndex;
				            	}
				            }
				            
				       
				            int timesNumber = Integer.parseInt(ta2.getText().trim(), 10);
				            
				            int[] integers = new int[validIndex*timesNumber];
				            for(int i=0; i<timesNumber; ++i)
				             for(int j=0; j<validIndex; ++j)
				            	integers[i*validIndex + j] = integersTmp[j];
				            
				            diagram.setCapturedData(new CapturedData(integers, integers.length,200000000,16,-4));
				            DeviceController.getExternalData = true;
				            DeviceController.externalCapturedData = new CapturedData(integers, integers.length,200000000,16,-4);
				            
				        }
				    });
				    
				    closeBtn.addActionListener(new ActionListener() {
				        public void actionPerformed(ActionEvent e)
				        {
				        	f.dispose();
				        }
				    });
				    
				    
				 
				
				f.setSize(500,400);
				f.setLocationRelativeTo(null); 
				f.setVisible(true);
				
			}else if (label.equals("Capture...")) {
				if (adc_controller.showCaptureDialog(frame) == DeviceController.DATA_READ) {
					diagram.setCapturedData(adc_controller.getDeviceData());
				}

			} else if (label.equals("Repeat Capture")) {
				if (adc_controller.showCaptureProgress(frame) == DeviceController.DATA_READ) {
					diagram.setCapturedData(adc_controller.getDeviceData());
				}

			} else if (label.equals("Exit")) {
				exit();
			
			} else if (label.equals("Zoom In")) {
				diagram.zoomIn();
			
			} else if (label.equals("Zoom Out")) {
				diagram.zoomOut();

			} else if (label.equals("Default Zoom")) {
				diagram.zoomDefault();

			} else if (label.equals("Diagram Settings...")) {
				diagram.showSettingsDialog(frame);
				
			} else if (label.equals("Labels...")) {
				diagram.showLabelsDialog(frame);

			} else if (label.equals("About")) {
				JOptionPane.showMessageDialog(null,
						"Sump's Logic Analyzer Client\n"
						+ "\n"
						+ "Copyright 2006 Michael Poppitz\n"
						+ "This software is released under the GNU GPL.\n"
						+ "\n"
						+ "For more information see:\n"
						+ "http://www.sump.org/projects/analyzer/",
					"About", JOptionPane.INFORMATION_MESSAGE
				);
			} else {
				// check if a tool has been selected and if so, process captured data by tool
				for (int i = 0; i < tools.length; i++)
					if (label.equals(tools[i].getName())) {
						CapturedData newData = tools[i].process(diagram.getCapturedData());
						if (newData != null)
							diagram.setCapturedData(newData);
					}
			}
			enableDataDependingFunctions(diagram.hasCapturedData());
				
		} catch(Exception E) {
			E.printStackTrace(System.out);
		}
	}
	
	
	private void redrawDiagramOnTextChanged(JTextArea ta, JRadioButton hex)
	{
		 //System.out.print(ta.getText());
        String[] integerStr = ta.getText().split(" ");
        //System.out.println(integerStr.toString());
        
        int[] integersTmp = new int[integerStr.length*2+1];
       
        int validIndex = 0;
        for(int i=0; i<integerStr.length; ++i)
        {
            integerStr[i].replace(" ", "");
        	if(!integerStr[i].equals(""))
        	{
            	//integers[i] =Integer.parseInt(integerStr[i].replace(" ", ""));
        		integersTmp[validIndex*2] =  hex.isSelected() ? Integer.parseInt(integerStr[i], 16) : Integer.parseInt(integerStr[i], 10);
        		integersTmp[validIndex*2 +1] = integersTmp[validIndex*2];
        	    ++validIndex;
        	}
        }
        
   
        integersTmp[validIndex*2] = 0;  // closing 0 tail
        int[] integers = new int[validIndex*2+1];
        for(int i=0; i<=validIndex*2; ++i)
        	integers[i] = integersTmp[i];
        
        diagram.setCapturedData(new CapturedData(integers, integers.length*2+1,200000000,16,-4));
    		
		
		
	}

	/** 
	 * Handles status change requests.
	 */
	public void statusChanged(String s) {
		status.setText(s);
	}
	
	/**
	 * Handles window close requests.
	 */
	public void windowClosing(WindowEvent event) {
		exit();
	}

	/**
	 * Load the given file as data.
	 * @param file file to be loaded as data
	 * @throws IOException when an IO error occurs
	 */
	public void loadData(File file) throws IOException {
		System.out.println("Opening: " + file.getName());
		diagram.setCapturedData(new CapturedData(file));
	}
	
	/**
	 * Load the given file as project.
	 * @param file file to be loaded as projects
	 * @throws IOException when an IO error occurs
	 */
	public void loadProject(File file) throws IOException {
		System.out.println("Opening Project: " + file.getName());
		project.load(file);
	}
	
	/**
	 * Starts GUI creation and displays it.
	 * Must be called be Swing event dispatcher thread.
	 */
	public void run() {
		createGUI();
	}
	
	/**
	 * Tells the main thread to exit. This will stop the VM.
	 */
	public void exit() {
		System.exit(0);
	}
		
	private JMenu toolMenu;
	private JMenu diagramMenu;
	private JLabel errorLabel = new JLabel();
	
	public static JRadioButton waveViewEnabled = new JRadioButton("Wave view");    // ?new2
	public static JRadioButton spectrumViewEnabled = new JRadioButton("Spectrum view");  // ?new2
	public static Diagram currDiagram;
	
	private JFileChooser fileChooser;
	private JFileChooser projectChooser;
	private DeviceController adc_controller;
	private DACController dac_controller;
	private Diagram diagram;
	private Project project;
	private JLabel status;
	private Tool[] tools;
	
	private JFrame frame;
}
