#Chain Data Ethereum
provider_url_eth = 'https://goerli.infura.io/v3/9a1872241b2d4248b4b074839c6d1832' #infura endpoint
chain_id = 5
contract_adress_eth = '0xc806d71f96eED5064Ad7AbE210Ad77d754C6B0CB'

#Chain Data IOTA
# provider_url_iota = 'https://api.sc.testnet.shimmer.network/evm/jsonrpc' #IOTA Shimmer
# chain_id = 1076

#Contract Data
abi = [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "createShipment",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "endShipment",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			},
			{
				"internalType": "enum Shipments.routeSteps[]",
				"name": "_route",
				"type": "uint8[]"
			}
		],
		"name": "setRoute",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_delId",
				"type": "uint256"
			}
		],
		"name": "shipmentMoved",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "shipmentPacked",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "checkIfShipmentExists",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "getCurrentStep",
		"outputs": [
			{
				"internalType": "enum Shipments.routeSteps",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "getFullRoute",
		"outputs": [
			{
				"internalType": "enum Shipments.routeSteps[]",
				"name": "_route",
				"type": "uint8[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_shipmentId",
				"type": "uint256"
			}
		],
		"name": "getNextStep",
		"outputs": [
			{
				"internalType": "enum Shipments.routeSteps",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]

#Wallet data
public_key = '0x6bff6f5646A64A24d4fd461563EAFA6E06DF6879'
private_key = '501efcd8e089d6393e2fe04ad67518d5d65094eadb4c85509a4f8dbb026a9b0d'