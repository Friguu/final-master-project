from CONFIG import *
from web3 import Web3

# This python script contains the Smartcontract class which
# controls every interaction with the shipment smart contract

class Smartcontract:
    def __init__(self):

        # Initially connect to a blockchain network
        self.w3 = self.connect_to_network()

        # Create an instance of the smart contract
        self.contract = self.w3.eth.contract(address=contract_adress_eth, abi = abi)        

    # Connects to the HTTP provider (Infura endpoint for Sepolia testnet)
    def connect_to_network(self):
        return Web3(Web3.HTTPProvider(provider_url_eth))
    
    # Returns whether a shipment exists or not
    def call_shipment_exists(self, shipment_id):
        # Call smart contract function and either return true or false
        return self.contract.functions.checkIfShipmentExists(shipment_id).call()
    
    # Calls the smart contract function to move a shipment 
    def call_move_shipment(self, shipment_id, step_type):

        # Build an unsigned transaction with function call
        tx = self.contract.functions.shipmentMoved(shipment_id, step_type).buildTransaction({
                            "gasPrice": self.w3.eth.gas_price,
                            "chainId": chain_id,
                            "from": public_key,
                            "nonce": self.w3.eth.getTransactionCount(public_key)
                        })
        
        # Sign the transaction
        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key)
        # Send the transaction and store transaction hash
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        # Get transaction receipt with transaction hash
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