# RF-BRIDGE-UWA-ELEC5552-PROJECT2-TEAM4
Ethernet-to-RF BRIDGE

It is a project of UWA students, group 4 in 2021

For Test Platform (DE10-lite)
	Loopback with XPORT and FPGA attached:
	
		FPGA      -> FPGA	  // For loop back
		GPIO(28) -> GPIO(29) 	  // CTS/RTS of RF module connect together in purpose of loop back
		GPIO(10) -> GIPO(11) 	  // TX/RX of RF module connect together in purpose of loop back
		
		FPGA      -> XPORT
		GPIO(0)  -> PIN4 	  // FPGA RX connect with XPORT data out
		GPIO(1)  -> PIN5 	  // FPGA TX connect with XPORT data in
		GPIO(2)  -> PIN6	  // FPGA CTS connect to the XPORT RTS
		GPIO(3)  -> PIN8	  // FPGA RTS connect to the XPORT CTS
