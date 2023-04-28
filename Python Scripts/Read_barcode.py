import serial
from Smartcontract import Smartcontract

class Reader:
    def __init__(self):
        self.smartcontract = Smartcontract()
        self.serial = serial.Serial('/dev/ttyACM0',19200, timeout = 0.5)

    def read_serial(self):
        while True:
            self.serial.read()
            scanned_data = self.serial.read(self.serial.in_waiting).decode()
            if len(scanned_data) != 0:
                print(scanned_data) #ausgabe anpassen
                if self.shipment_exists(self.get_shipment_id(scanned_data)):
                    self.move_shipment(shipment_id=self.get_shipment_id(scanned_data), step_type=self.get_step_type(scanned_data))
                    

    def shipment_exists(self, shipment_id):
        return self.smartcontract.call_shipment_exists(shipment_id)
    
    def get_shipment_id(self, scanned_data):
        #string pattern of scanned_data: SHIPMENTID&&STEPTYPE
        x = scanned_data.split('&&')
        return x[0]
    
    def get_step_type(self, scanned_data):
        #string pattern of scanned_data: SHIPMENTID&&STEPTYPE
        x = scanned_data.split('&&')
        return x[1]
    
    def move_shipment(self, shipment_id, step_type):
        self.smartcontract.call_move_shipment(shipment_id=shipment_id, step_type=step_type)

def main(): 
    rd = Reader()
    print(rd.get_step_type('asdafasdfgwse&&123'))

if __name__ == '__main__':
    main()