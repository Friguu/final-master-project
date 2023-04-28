from CONFIG import *
from web3 import Web3

class Smartcontract:
    def __init__(self):
        self.w3 = self.connect_to_network()
        self.contract = self.w3.eth.contract(address=contract_adress_eth, abi = abi)        

    def connect_to_network(self):
        return Web3(Web3.HTTPProvider(provider_url_eth))
    
    def get_contract_abi(self):
        return abi
    
    def call_shipment_exists(self, shipment_id):
        #call if exists
        return self.contract.functions.checkIfShipmentExists(shipment_id).call()
    
    def call_move_shipment(self, shipment_id, step_type):
        tx = self.contract.functions.shipmentMoved(shipment_id, step_type).buildTransaction({
                            "gasPrice": self.w3.eth.gas_price,
                            "chainId": chain_id,
                            "from": public_key,
                            "nonce": self.w3.eth.getTransactionCount(public_key)
                        })
        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        print(tx_receipt)
        return True


def main():
    pass
    #sc = Smartcontract()
    #print(sc.call_shipment_exists(1234))
    #sc.get_shipment_hash(123)

if __name__ == '__main__':
    main()