// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Shipments {

//__________________________________________________________________________________________________________________________________
    //Events

    //Event emitted when a delivery step is reached
    event deliveryStepReached(uint256 indexed _shipmentId, deliverySteps _step);

    //Event emitted when a shipping step is reached
    event shippingStepReached(uint256 indexed _shipmentId, shipmentSteps _step);

//__________________________________________________________________________________________________________________________________
    //Data for shipment -> all data needed for the shipment state

    //this enum contains every step that a shipment goes through the whole process from start to destination
    enum shipmentSteps{ Initialized,                //0
                        Created,                    //1
                        ReadyForPickup,     	    //2
                        OnDelivery,                 //3
                        WarehouseReached,           //4
                        ReadyForFinalDelivery,      //5
                        OnFinalDelivery,            //6
                        Arrived,                    //7
                        ShipmentDone }              //8

    //this mapping contains the current shipping state for each shipment ID
    mapping(uint256 => shipmentSteps) shipmentStep;    

//__________________________________________________________________________________________________________________________________
    //Data for delivery -> all data needed for the delivery state

    //This enum represents all possible steps for a delivery process from one place to another (e.g. warehouse A to warehouse B)
    enum deliverySteps{ Initialized,                    //0
                        ShipmentLoaded,                 //1  
                        OnFirstIntermediateDelivery,    //2
                        OnMainDelivery,                 //3
                        OnSecondIntermediateDelivery,   //4
                        DeliveryDone,                   //5
                        Arrived }                       //6
    
    //This mapping contains the current delivery state for each shipment ID
    mapping(uint256 => deliverySteps) deliveryStep;

//_________________________________ _________________________________________________________________________________________________
    //Data for Route -> all data needed for the route of a shipment

    //An initial step is in this case not required, so we start with the first state at position 0
    enum routeSteps{PickupLocation,         //0
                    Truck,                  //1
                    Plane,                  //2
                    Ship,                   //3
                    Train,                  //4
                    Warehouse,              //5
                    Destination }           //6
    
    //This struct contains all data needed for one step in the route of a shipment
    struct stcRouteStep {
        routeSteps step;
        bool isPlace;
        bool done;
    }

    //This mapping has an array of an undefined length with all steps needed to bring the shipment from
    //the Pickup Location to the Destination (not necessary in the order or all values of the enum)
    mapping(uint256 => stcRouteStep[]) routes;

    //Since an array is needed for the route, it is necessary to keep track of the current step as index of the array
    mapping(uint256 => uint256) public currentStepIndex;

//__________________________________________________________________________________________________________________________________
    //Initialization -> everything needed for the initialization when deployed
    constructor() {
        //Currently nothing needed for the constructor
    }

//__________________________________________________________________________________________________________________________________
    //Entrypoints -> all functions that act as public entrypoints of the smart contract
                        //without read-only getter-functions

    //This function acts as initial entrypoint which sets the "Created" state for the shipment ID
    function createShipment(uint256 _shipmentId) public returns(bool) {

        //Shipment has to be in state "Initialized" which means, that the shipment not yet exists
        require(!checkIfShipmentExists(_shipmentId), 'Shipment with this ID already exists.');

        shipmentStep[_shipmentId] = shipmentSteps.Created;

        emit shippingStepReached(_shipmentId, shipmentSteps.Created);

        return true;

    }

    //This function represents the next step in the process, when the shipment gets packed after creation
    function shipmentPacked(uint256 _shipmentId) public {

        require(shipmentStep[_shipmentId] == shipmentSteps.Created, 'Shipment already packed or further in the process.');

        shipmentStep[_shipmentId] = shipmentSteps.ReadyForPickup;

        emit shippingStepReached(_shipmentId, shipmentSteps.ReadyForPickup);

    }

    //For every other step in the shipping and delivery process, this function is the entrypoint
    //Parameters:
        //_shipmentId: Identifier of the shipment
        //_stepType: 1 -> delivery process; 2 -> shipping process
    function shipmentMoved(uint256 _shipmentId, uint256 _stepType) public returns(bool) {

        //Get the current and the next route step for further processing
        routeSteps currStep = routeSteps(getCurrShippingStep(_shipmentId));
        routeSteps nextStep = routeSteps(getNextShippingStep(_shipmentId));

        //Depending on the current state of the shipment, there are dedicated functions.
        //So it has to be secured, that the shipment has the right state for this function
        require(checkIfShipmentExists(_shipmentId), "Shipment does not exists. Please create and pack it first.");
        require(shipmentStep[_shipmentId] != shipmentSteps.Created, "Shipment has to be packed first.");
        require(shipmentStep[_shipmentId] != shipmentSteps.Arrived, "Shipment can't be moves because it already arrived");

        //Requires for delivery process
        if (_stepType == 1) {
            //For a delivery, the shipment state has to be "on delivery" or "on final delivery"
            require(shipmentStep[_shipmentId] == shipmentSteps.OnDelivery || 
                    shipmentStep[_shipmentId] == shipmentSteps.OnFinalDelivery, 
                    "Shipment has to be on delivery to move further in the delivery process");
        } 

        //Requires for shipping process
        if (_stepType == 2) {
            //To move further in the shipping process, the delivery process has to be finished
            require(deliveryStep[_shipmentId] == deliverySteps.Initialized ||
                    deliveryStep[_shipmentId] == deliverySteps.DeliveryDone, 
                    "Delivery process has to be finished first.");
        } 
        
        //Sep type = 1 -> delivery process
        //Move the shipment further the delivery process
        if (_stepType == 1) {
            
            if( currStep == routeSteps.Truck ) {
                
                if (deliveryStep[_shipmentId] == deliverySteps.ShipmentLoaded) {
                    //A delivery by truck has no intermediate delivery step, so we set it to the main delivery
                    onMainDelivery(_shipmentId);
                    return true;
                } else {
                    deliveryDone(_shipmentId);
                    return true;
                }
                
            } else if ( currStep == routeSteps.Plane || 
                        currStep == routeSteps.Ship || 
                        currStep == routeSteps.Train) {

                //For a delivery by Plan, Ship or Train we assume, that there has to be an
                //intermediate delivery step, to get the package e.g. from the warehouse to the airport
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

        //Delivery ID = 2 -> shipping process
        //Move the shipment further the shipping process
        } else if (_stepType == 2) {

            //Count up the step index to keep up the right index for the array to access the route steps
            if(currStep == routeSteps.PickupLocation) {
                currentStepIndex[_shipmentId] += 1;
                pickupShipment(_shipmentId);
            } else if ( nextStep == routeSteps.Truck || 
                        nextStep == routeSteps.Plane || 
                        nextStep == routeSteps.Ship || 
                        nextStep == routeSteps.Train ||
                        currStep == routeSteps.Warehouse ) {
                currentStepIndex[_shipmentId] += 1;
                onDeliveryShipment(_shipmentId);
                return true;
            } else if(nextStep == routeSteps.Warehouse) {
                currentStepIndex[_shipmentId] += 1;
                warehouseReachedShipment(_shipmentId);
                return true;
            } else if (nextStep == routeSteps.Destination) {
                currentStepIndex[_shipmentId] += 1;
                arrivedShipment(_shipmentId);
                return true;
            }
            
        }

        return false;
        
    }

    //Change the state to done, when the shipping process is finished
    //This function could also be called at any step of the process, e.g. when the order is cancelled
    function endShipment(uint256 _shipmentId) public returns(bool) {

        shipmentStep[_shipmentId] = shipmentSteps.ShipmentDone;
        deliveryStep[_shipmentId] = deliverySteps.Arrived;

        emit shippingStepReached(_shipmentId, shipmentSteps.ShipmentDone);

        return true;

    }

    //Function to set the shipping route for a shipment
    function setRoute(uint256 _shipmentId, routeSteps[] memory _route) public returns(bool) {

        //It is only possible to set a route, if a shipment has already been created
        require(checkIfShipmentExists(_shipmentId), "Shipment has to be created first in order to set a route!");

        //iterare through the input array and push each step to the mapping for the route
        for (uint256 i = 0; i < _route.length; i++) {
            routes[_shipmentId].push(stcRouteStep(_route[i], isPlace(_route[i]), false));
        }
        currentStepIndex[_shipmentId] = 0;

        return true;

    }

//__________________________________________________________________________________________________________________________________
    //Shipment -> all functions that work around the state of the shipment

    //Internal function for when the shipment is picked up
    function pickupShipment(uint256 _shipmentId) private {

        //A shipment can only be picked up, if it is ready to be picked up
        require(shipmentStep[_shipmentId] == shipmentSteps.ReadyForPickup ||
                shipmentStep[_shipmentId] == shipmentSteps.ReadyForFinalDelivery,
                "Shipment not ready to be picked up!");

        //Set shipment state to on delivery
        shipmentStep[_shipmentId] = shipmentSteps.OnDelivery;
        emit shippingStepReached(_shipmentId, shipmentSteps.OnDelivery);
        
        //Start the delivery process
        deliveryStep[_shipmentId] = deliverySteps.ShipmentLoaded;
        emit deliveryStepReached(_shipmentId, deliverySteps.ShipmentLoaded);

    }
        
    //Internal function to handle the shipment beeing on delivery
    function onDeliveryShipment(uint256 _shipmentId) private {

        //Set the step on final delivery or on delivery
        if (isFinalStep(_shipmentId)) {
            shipmentStep[_shipmentId] = shipmentSteps.OnFinalDelivery;
            emit shippingStepReached(_shipmentId, shipmentSteps.OnFinalDelivery);
        } else {
            shipmentStep[_shipmentId] = shipmentSteps.OnDelivery;
            emit shippingStepReached(_shipmentId, shipmentSteps.OnDelivery);
        }

        //Start the delivery process
        deliveryPickedUp(_shipmentId);
        
    }

    //This internal function handles the situation, if a shipment reaches a warehouse
    function warehouseReachedShipment(uint256 _shipmentId) private {

        //A shipment can only reach a warehouse, if the delivery process is done and the
        //shipment is currently on delivery
        require(shipmentStep[_shipmentId] == shipmentSteps.OnDelivery ||
                deliveryStep[_shipmentId] == deliverySteps.DeliveryDone,
                "Delivery process not yet finished!");

        //If the warehouse is the last place before the final delivery to the customer
        //the shipment is ready for the final delivery
        if (isFinalStep(_shipmentId)) {
            shipmentStep[_shipmentId] = shipmentSteps.ReadyForFinalDelivery;
            emit shippingStepReached(_shipmentId, shipmentSteps.ReadyForFinalDelivery);
        } else {
            shipmentStep[_shipmentId] = shipmentSteps.WarehouseReached;
            emit shippingStepReached(_shipmentId, shipmentSteps.WarehouseReached);
        }

        //If the shipment reaches a warehouse, the delivery process is done and needs to be initialized again
        deliveryStep[_shipmentId] = deliverySteps.Initialized;
        
    }  

    //Internal function for when the shipment arrived at its destination
    function arrivedShipment(uint256 _shipmentId) private {

        //A shipment can only arrive the destination, if it is on its final delivery
        require(shipmentStep[_shipmentId] == shipmentSteps.OnFinalDelivery, 
                "Shipment can only arrive, if it is on its final delivery!");

        //Set the arrived state
        shipmentStep[_shipmentId] = shipmentSteps.Arrived;
        emit shippingStepReached(_shipmentId, shipmentSteps.Arrived);

        //Reset the delivery process
        deliveryStep[_shipmentId] = deliverySteps.Initialized;

    }  

//__________________________________________________________________________________________________________________________________
    //Delivery Process -> all functions that work around the state of the delivery process

    //Internal function to start the delivery process
    function deliveryPickedUp(uint256 _shipmentId) private {

        //A shipment has to be "on delivery" to be loaded
        require(shipmentStep[_shipmentId] == shipmentSteps.OnDelivery ||
                shipmentStep[_shipmentId] == shipmentSteps.OnFinalDelivery,
                "Shipment has to be on delivery!");

        deliveryStep[_shipmentId] = deliverySteps.ShipmentLoaded;

        emit deliveryStepReached(_shipmentId, deliverySteps.ShipmentLoaded);

    }

    //Internal function for the first intermediate delivery
    function onFirstIntermediateDelivery(uint256 _shipmentId) private {

        //To be on a delivery step, the shipment has to be loaded
        require(deliveryStep[_shipmentId] == deliverySteps.ShipmentLoaded,
                "Shipment has to be loaded to be on delivery!");

        deliveryStep[_shipmentId] = deliverySteps.OnFirstIntermediateDelivery;

        emit deliveryStepReached(_shipmentId, deliverySteps.OnFirstIntermediateDelivery);

    }

    //Internal function for the main delivery
    function onMainDelivery(uint256 _shipmentId) private {

        //To be on main delivery, the shipment has to be loaded or on first intermediate delivery
        require(deliveryStep[_shipmentId] == deliverySteps.ShipmentLoaded ||
                deliveryStep[_shipmentId] == deliverySteps.OnFirstIntermediateDelivery,
                "Shipment not yet ready for main delivery!");

        deliveryStep[_shipmentId] = deliverySteps.OnMainDelivery;

        emit deliveryStepReached(_shipmentId, deliverySteps.OnMainDelivery);

    }

    //Internal function for the second intermediate delivery
    function onSecondIntermediateDelivery(uint256 _shipmentId) private {

        //To be on a delivery step, the shipment has to be loaded
        require(deliveryStep[_shipmentId] == deliverySteps.OnMainDelivery,
                "Shipment has to be on main delivery!");

        deliveryStep[_shipmentId] = deliverySteps.OnSecondIntermediateDelivery;

        emit deliveryStepReached(_shipmentId, deliverySteps.OnSecondIntermediateDelivery);

    }

    //Internal function to finalize the delivery
    function deliveryDone(uint256 _shipmentId) private {

        //To finish the delivery process, the shipment has to be on main delivery or second intermediate delivery
        require(deliveryStep[_shipmentId] == deliverySteps.OnMainDelivery ||
                deliveryStep[_shipmentId] == deliverySteps.OnSecondIntermediateDelivery,
                "Delivery process not yet ready to be finished!");

        deliveryStep[_shipmentId] = deliverySteps.DeliveryDone;

        emit deliveryStepReached(_shipmentId, deliverySteps.DeliveryDone);

    }

//__________________________________________________________________________________________________________________________________
    //Route -> all functions that work around the route of a shipment

    //Internal function to check if the given route step is a place or not
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

    //Internal function to check if the shipment is currently on the final step.
    function isFinalStep(uint256 _shipmentId) private view returns(bool) {

        //If the current index+2 extends the maximum of the route, it already is on its final delivery
        require((currentStepIndex[_shipmentId] + 1) <= routes[_shipmentId].length-1, 
                "Shipment already on its final delivery!");
        
        //Initialize variable with the index of the step after next
        uint256 i = currentStepIndex[_shipmentId] + 1;

        //When the route step after next is a place and the last step 
        if (routes[_shipmentId][i].isPlace && i == routes[_shipmentId].length-1) {
            //We know the next pace is the destination
            return true;
        } else {
            return false;
        }
           
    }

//__________________________________________________________________________________________________________________________________
    //Getter -> all read-only functions that return info

    //Getter function that returns an array with the full route set for a shipment
    function getFullRoute(uint256 _shipmentId) public view returns(routeSteps[] memory _route) {

        //Initialize an array with the length of the array with the route steps
        routeSteps[] memory returnArray = new routeSteps[](routes[_shipmentId].length);

        //Iterate through the whole route and pass it to the return array
        for (uint256 i = 0; i < routes[_shipmentId].length; i++) {
            returnArray[i] = routes[_shipmentId][i].step;
        }
        
        return returnArray;

    }

    //Getter function that returns the current shipping step
    function getCurrShippingStep(uint256 _shipmentId) public view returns(routeSteps) {

        return routes[_shipmentId][currentStepIndex[_shipmentId]].step;
        
    }

    //Getter function that returns the current delivery step
    function getCurrDeliveryStep(uint256 _shipmentId) public view returns(deliverySteps) {

        return deliveryStep[_shipmentId];
        
    }
    
    //Getter function that returns the next step of a shipment
    function getNextShippingStep(uint256 _shipmentId) public view returns(routeSteps) {

        //Take into account, that this function could be called when the last step is reached.
        //To prevent accessing the array with an too high index, check if the current
        //step index is lower than the highest index in the route array
        if((routes[_shipmentId].length - 1) > currentStepIndex[_shipmentId]) {
            return routes[_shipmentId][currentStepIndex[_shipmentId]+1].step;
        } else { //If the shipment is on the last step in the array, just return the current step
            return routes[_shipmentId][currentStepIndex[_shipmentId]].step;
        }

    }

    //Getter function that returns the current state of the shipment
    function getCurrShipmentState(uint256 _shipmentId) public view returns(shipmentSteps) {

        return shipmentStep[_shipmentId];
        
    }

//__________________________________________________________________________________________________________________________________
    //Utils -> utility functions for internal and public use

    //Public function to check if a shipment "exists" which means its not in "Initialized" state
    function checkIfShipmentExists(uint256 _shipmentId) public view returns(bool) {

        if (shipmentStep[_shipmentId] == shipmentSteps.Initialized) {
            return false;
        } else {
            return true;
        }
        
    }

}