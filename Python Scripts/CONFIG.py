#Chain Data Ethereum
provider_url_eth = 'https://sepolia.infura.io/v3/7ed06f3d7d494083b61ac9ff1c572fac' #infura endpoint
chain_id = 11155111
contract_adress_eth = ''

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

#Wallet data -> test wallet, so it is fine if you see that! :)
public_key = '0x6bff6f5646A64A24d4fd461563EAFA6E06DF6879'
private_key = '501efcd8e089d6393e2fe04ad67518d5d65094eadb4c85509a4f8dbb026a9b0d'