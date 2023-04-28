import serial

class Reader:
    def __init__(self):
        self.shipment_id = ''
        self.shipment_hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
        self.serial = serial.Serial('/dev/ttyACM0',19200, timeout = 0.5)

    def read_serial(self):
        while True:
            self.serial.read()
            scanned_data = self.serial.readline(self.serial.in_waiting).decode()
            if len(scanned_data) != 0:
                print('Scanned data from Barcode:', scanned_data)
                if self.verify_barcode(scanned_data):
                    print('Barcode verified')
                else:
                    print('Barcode not verified')

    def verify_barcode(self, code_data):
        self.shipment_id = self.get_shipment_id(code_data)
        print(type(code_data))
        print(type(self.shipment_hash))
        print(type(code_data[5:]))
        if code_data[5:-1].encode('UTF-8') == self.shipment_hash.encode('UTF-8'):
            return True
        else:
            return False #-> returns False

    def get_shipment_id(self, code_data):
        return code_data[:5]


def main():

    Reader().read_serial()

if __name__ == '__main__':
    main()
