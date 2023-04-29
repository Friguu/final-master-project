import serial
from Smartcontract import Smartcontract

# This python script is meant to run on an raspberry pi that has an USB Barcode Scanner attached to the given port.
# It is highly individualized to my personal setup. The react app offers the same functionality to try out the Smart Contract

class Reader:
    def __init__(self):

        # Initialize an instance of imported Smartcontract class
        self.smartcontract = Smartcontract() 

        # Initialize an instance of serial class to access serial ports of the raspberry pi
        self.serial = serial.Serial('/dev/ttyACM0',19200, timeout = 0.5) 

    def read_serial(self):

        # Start an endless loop
        while True:
            # Reads the serial data every 0.5 sec (timeout parameter)
            self.serial.read()
            # Returns the decoded byte data read from the serial port
            scanned_data = self.serial.read(self.serial.in_waiting).decode()

            # There is not necessary data read, so we only want to process further if there is some read data
            if len(scanned_data) != 0:
                # Check if the shipment of the scanned barcode exists
                if self.shipment_exists(self.get_shipment_id(scanned_data)):
                    # Then moves the shipment -> assumes the shipment is created and packed
                    self.move_shipment(shipment_id=self.get_shipment_id(scanned_data), step_type=self.get_step_type(scanned_data))
                    
    # Calls the smart contract class to check if the shipment exists
    def shipment_exists(self, shipment_id):
        return self.smartcontract.call_shipment_exists(shipment_id)
    
    # Extracts the shipment ID of the barcode data
    def get_shipment_id(self, scanned_data):
        # String pattern of barcode data: SHIPMENTID&&STEPTYPE
        x = scanned_data.split('&&')
        return x[0]
    
    # Extracts the step type of the barcode data
    def get_step_type(self, scanned_data):
        # String pattern of barcode data: SHIPMENTID&&STEPTYPE
        x = scanned_data.split('&&')
        return x[1]
    
    # Calls the smart contract class to move the shipment
    def move_shipment(self, shipment_id, step_type):
        self.smartcontract.call_move_shipment(shipment_id=shipment_id, step_type=step_type)

def main(): 
    rd = Reader()
    print(rd.get_step_type('asdafasdfgwse&&123'))

if __name__ == '__main__':
    main()