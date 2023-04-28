// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Shipments {

    //TODOS
    //source for enum with init state
    //require sTatements
            //plus feedback text

//__________________________________________________________________________________________________________________________________
    //Data for shipment -> all data needed for the shipment state

    //In a mapping with enums, solidity creates all possible values with 0, so if the state enum starts with 0
    //the mapping creates all possible values with the first state. So the first state must be a "placeholder"
    //and the actual state starts with the second enum value which is internally represented as 1.

    //this enum contains every step that a shipment goes through the whole process from start to destination
    enum shipmentSteps{ Initialized,                //0
                        Created,                    //1
                        ReadyForPickup,     	    //2
                        OnDelivery,                 //3
                        StepReached,                //4
                        ReadyForFinalDelivery,      //5
                        OnFinalDelivery,            //6
                        Arrived,                    //7
                        ShipmentDone }              //8

    //this mapping contains the current shipping state for each shipment ID
    mapping(uint256 => shipmentSteps) shipmentStep;    

//__________________________________________________________________________________________________________________________________
    //Data for delivery -> all data needed for the delivery state

    //In a mapping with enums, solidity creates all possible values with 0, so if the state enum starts with 0
    //the mapping creates all possible values with the first state. So the first state must be a "placeholder"
    //and the actual state starts with the second enum value which is internally represented as 1.

    //this enum represents all possible steps for a delivery process from one place to another (e.g. warehouse A to warehouse B)
    enum deliverySteps{ Initialized,                    //0
                        ShipmentLoaded,                 //1  
                        OnFirstIntermediateDelivery,    //2
                        OnMainDelivery,                 //3
                        OnSecondIntermediateDelivery,   //4
                        DeliveryDone }                  //5
    
    //this mapping contains the current delivery state for each shipment ID
    mapping(uint256 => deliverySteps) deliveryStep;

//_________________________________ _________________________________________________________________________________________________
    //Data for Route -> all data needed for the route of a shipment

    //an initial step is in this case not required, so we start with the first state at position 0
    enum routeSteps{PickupLocation,         //0
                    Truck,                  //1
                    Plane,                  //2
                    Ship,                   //3
                    Train,                  //4
                    Warehouse,              //5
                    Destination }           //6
    
    //this struct contains all data needed for one step in the route of a shipment
    struct stcRouteStep {
        routeSteps step;
        bool isPlace;
        bool done;
    }

    //this mapping has an array of an undefined length with all steps needed to bring the shipment from
    //the Pickup Location to the Destination (not necessary in the order or all values of the enum)
    mapping(uint256 => stcRouteStep[]) routes;

    //since an array is needed for the route, it is necessary to keep track of the current step as index of the array
    mapping(uint256 => uint256) currentStepIndex;

//__________________________________________________________________________________________________________________________________
    //Initialization -> everything needed for the initialization when deployed
    constructor() {
        //currently nothing needed for the constructor
    }

//__________________________________________________________________________________________________________________________________
    //Entrypoints -> all functions that act as public entrypoints of the smart contract
                        //without read-only getter-functions

    //create shipment
    function createShipment(uint256 _shipmentId) public returns(bool) {
        //Shipment has to be in state "Initialized" which means, that the shipment not yet exists
        require(checkIfShipmentExists(_shipmentId), 'Shipment with this ID already exists.');

        shipmentStep[_shipmentId] = shipmentSteps.Created;
        return true;
    }

    //shipment packed 
    function shipmentPacked(uint256 _shipmentId) public {
        require(shipmentStep[_shipmentId] == shipmentSteps.Created, 'Shipment already packed.');
        shipmentStep[_shipmentId] = shipmentSteps.ReadyForPickup;
    }

    //move shipment
    function shipmentMoved(uint256 _shipmentId, uint256 _stepType) public returns(bool) {

        routeSteps currStep = routeSteps(getCurrentStep(_shipmentId));
        routeSteps nextStep = routeSteps(getNextStep(_shipmentId));

        require(!checkIfShipmentExists(_shipmentId));
        require(shipmentStep[_shipmentId] != shipmentSteps.Created);
        require(shipmentStep[_shipmentId] != shipmentSteps.Arrived);

        //requires for DelID 1
        if (_stepType == 1) {
            require(shipmentStep[_shipmentId] == shipmentSteps.OnDelivery || 
                        shipmentStep[_shipmentId] == shipmentSteps.OnFinalDelivery);
        } 

        //requires for DelID 2
        if (_stepType == 2) {
            require(deliveryStep[_shipmentId] == deliverySteps.DeliveryDone ||
                        deliveryStep[_shipmentId] == deliverySteps.Initialized);
        } 
        
        //Delivery ID = 1 -> delivery process
        if (_stepType == 1) {

            if( currStep == routeSteps.Truck ) {

                if (deliveryStep[_shipmentId] == deliverySteps.ShipmentLoaded) {
                    onMainDelivery(_shipmentId);
                    return true;
                } else {
                    deliveryDone(_shipmentId);
                    return true;
                }
                
            } else if ( currStep == routeSteps.Plane || 
                        currStep == routeSteps.Ship || 
                        currStep == routeSteps.Train) {
                
                if (deliveryStep[_shipmentId] == deliverySteps.ShipmentLoaded) {
                    onFirstIntermediateDelivery(_shipmentId);
                    return true;
                } else if (deliveryStep[_shipmentId] == deliverySteps.OnFirstIntermediateDelivery) {
                    onMainDelivery(_shipmentId);
                    return true;
                } else if (deliveryStep[_shipmentId] == deliverySteps.OnMainDelivery) {
                    onSecondIntermediateDelivery(_shipmentId);
                    return true;             
                } else if (deliveryStep[_shipmentId] == deliverySteps.OnSecondIntermediateDelivery) {
                    deliveryDone(_shipmentId);
                    return true;
                }

            }

        //Delivery ID = 2 -> shipment process 
        } else if (_stepType == 2) {

            if(currStep == routeSteps.PickupLocation) {
                currentStepIndex[_shipmentId] += 1;
                pickupShipment(_shipmentId);
            } else if ( nextStep == routeSteps.Truck || 
                        nextStep == routeSteps.Plane || 
                        nextStep == routeSteps.Ship || 
                        nextStep == routeSteps.Train) {
                currentStepIndex[_shipmentId] += 1;
                onDeliveryShipment(_shipmentId);
                return true;
            } else if(nextStep == routeSteps.Warehouse) {
                currentStepIndex[_shipmentId] += 1;
                stepReachedShipment(_shipmentId);
                return true;
            } else if (currStep == routeSteps.Destination) {
                currentStepIndex[_shipmentId] += 1;
                arrivedShipment(_shipmentId);
                return true;
            }
            
        }

        return false;
        
    }

    //shipping done
    function endShipment(uint256 _shipmentId) public returns(bool) {
        shipmentStep[_shipmentId] = shipmentSteps.ShipmentDone;
        return true;
    }

    //setRoute
    function setRoute(uint256 _shipmentId, routeSteps[] memory _route) public returns(bool) {
        require(!checkIfShipmentExists(_shipmentId));
        for (uint256 i = 0; i < _route.length; i++) {
            routes[_shipmentId].push(stcRouteStep(_route[i], isPlace(_route[i]), false));
        }
        currentStepIndex[_shipmentId] = 0;
        return true;
    }

//__________________________________________________________________________________________________________________________________
    //Shipment -> all functions that work around the state of the shipment

    //shipment ready4pickup
    function pickupShipment(uint256 _shipmentId) private {
        shipmentStep[_shipmentId] = shipmentSteps.OnDelivery;
        deliveryStep[_shipmentId] = deliverySteps.ShipmentLoaded;
    }
        
    //shipment on delivery
    function onDeliveryShipment(uint256 _shipmentId) private {
        
        if (isFinalStep(_shipmentId)) {
            shipmentStep[_shipmentId] = shipmentSteps.OnFinalDelivery;
        } else {
            shipmentStep[_shipmentId] = shipmentSteps.OnDelivery;
        }

        deliveryPickedUp(_shipmentId);
        
    }

    //shipment step reached
    function stepReachedShipment(uint256 _shipmentId) private {

        if (isFinalStep(_shipmentId)) {
            shipmentStep[_shipmentId] = shipmentSteps.ReadyForFinalDelivery;
        } else {
            shipmentStep[_shipmentId] = shipmentSteps.StepReached;
        }

        deliveryStep[_shipmentId] = deliverySteps.Initialized;
        
    }  

    //shipment arrived
    function arrivedShipment(uint256 _shipmentId) private {
        shipmentStep[_shipmentId] = shipmentSteps.Arrived;
        deliveryStep[_shipmentId] = deliverySteps.Initialized;
    }  

//__________________________________________________________________________________________________________________________________
    //Delivery Process -> all functions that work around the state of the delivery process

    //picked up
    function deliveryPickedUp(uint256 _shipmentId) private {
        deliveryStep[_shipmentId] = deliverySteps.ShipmentLoaded;
    }

    //OnFirstIntermediateDelivery
    function onFirstIntermediateDelivery(uint256 _shipmentId) private {
        deliveryStep[_shipmentId] = deliverySteps.OnFirstIntermediateDelivery;
    }

    //OnMainDelivery
    function onMainDelivery(uint256 _shipmentId) private {
        deliveryStep[_shipmentId] = deliverySteps.OnMainDelivery;
    }

    //OnSecondIntermediateDelivery
    function onSecondIntermediateDelivery(uint256 _shipmentId) private {
        deliveryStep[_shipmentId] = deliverySteps.OnSecondIntermediateDelivery;
    }

    //DeliveryDone
    function deliveryDone(uint256 _shipmentId) private {
        deliveryStep[_shipmentId] = deliverySteps.DeliveryDone;
    }

//__________________________________________________________________________________________________________________________________
    //Route -> all functions that work around the route of a

    //check if step is a place
    function isPlace(routeSteps _step) private pure returns(bool) {
        if( _step == routeSteps.PickupLocation || 
            _step == routeSteps.Warehouse || 
            _step == routeSteps.Destination) {
                return true;
        } else if ( _step == routeSteps.Truck || 
                    _step == routeSteps.Plane || 
                    _step == routeSteps.Ship || 
                    _step == routeSteps.Train) {
                return false;
        } else {
            return false;
        } 
    }

    //check if the reached step is the final step
    function isFinalStep(uint256 _shipmentId) private view returns(bool) {
        
        bool x = false;
        uint256 i = currentStepIndex[_shipmentId] + 1;

        while (i <= routes[_shipmentId].length-1) {

            if (routes[_shipmentId][i].isPlace && i == routes[_shipmentId].length-1) {
                x = true;
            } 

            i++;

        }

        if(x) {
            return true;
        } else {
            return false;
        }
        
    }

//__________________________________________________________________________________________________________________________________
    //Getter -> all read-only functions that return info

    //getFullRoute
    function getFullRoute(uint256 _shipmentId) public view returns(routeSteps[] memory _route) {
        routeSteps[] memory returnArray = new routeSteps[](routes[_shipmentId].length);

        for (uint256 i = 0; i < routes[_shipmentId].length; i++) {
            returnArray[i] = routes[_shipmentId][i].step;
        }
        
        return returnArray;
    }

    //getCurrentStep
    function getCurrentStep(uint256 _shipmentId) public view returns(routeSteps) {
        return routes[_shipmentId][currentStepIndex[_shipmentId]].step;
    }
    
    //getNextStep
    function getNextStep(uint256 _shipmentId) public view returns(routeSteps) {
        if((routes[_shipmentId].length - 1) > currentStepIndex[_shipmentId]) {
            return routes[_shipmentId][currentStepIndex[_shipmentId]+1].step;
        } else {
            return routes[_shipmentId][currentStepIndex[_shipmentId]].step;
        }
    }

//__________________________________________________________________________________________________________________________________
    //Utils -> utility functions for internal and public use

    //function called by the raspberry pi to check, if the shipment exist or not
    function checkIfShipmentExists(uint256 _shipmentId) public view returns(bool) {

        if (shipmentStep[_shipmentId] == shipmentSteps.Initialized) {
            return false;
        } else {
            return true;
        }
        
    }

}