// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Shipments {

    //TODOS
    //require sTatements
            //plus feedback text

//__________________________________________________________________________________________________________________________________
    //Data for shipment

    enum shipmentSteps{ Initialized,   //why init and created? because you have to check if the entry is already created or not
                        Created,       //in a mapping, all entries exist and are initialized with 0/false, so creations starts with 1
                        ReadyForPickup, 
                        OnDelivery,
                        StepReached, 
                        ReadyForFinalDelivery, 
                        OnFinalDelivery, 
                        Arrived, 
                        ShipmentDone }

    mapping(uint256 => shipmentSteps) shipmentStep;    

//__________________________________________________________________________________________________________________________________
    //Data for delivery

    enum deliverySteps{ Initialized,
                        ShipmentLoaded, 
                        OnFirstIntermediateDelivery,
                        OnMainDelivery,
                        OnSecondIntermediateDelivery,
                        DeliveryDone }
    
    mapping(uint256 => deliverySteps) deliveryStep;

//_________________________________ _________________________________________________________________________________________________
    //Data for Route

    enum routeSteps{PickupLocation, 
                    Truck,
                    Plane,
                    Ship,
                    Train,
                    Warehouse,
                    Destination }
    
    struct stcRouteStep {
        routeSteps step;
        bool isPlace;
        bool done;
    }

    mapping(uint256 => stcRouteStep[]) routes;

    mapping(uint256 => uint256) currentStepIndex;

//__________________________________________________________________________________________________________________________________
    //Initialization
    constructor() {
        
    }

//__________________________________________________________________________________________________________________________________
    //Entrypoints

    //create shipment
    function createShipment(uint256 _shipmentId) public returns(bool) {
        require(shipmentStep[_shipmentId] == shipmentSteps.Initialized);
        shipmentStep[_shipmentId] = shipmentSteps.Created;
        return true;
    }

    //shipment packed 
    function shipmentPacked(uint256 _shipmentId) public {
        shipmentStep[_shipmentId] = shipmentSteps.ReadyForPickup;
    }

    //move shipment
    function shipmentMoved(uint256 _shipmentId, uint256 _stepType) public returns(bool) {

        routeSteps currStep = routeSteps(getCurrentStep(_shipmentId));
        routeSteps nextStep = routeSteps(getNextStep(_shipmentId));

        require(shipmentStep[_shipmentId] != shipmentSteps.Initialized);
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
        require(shipmentStep[_shipmentId] != shipmentSteps.Initialized);
        for (uint256 i = 0; i < _route.length; i++) {
            routes[_shipmentId].push(stcRouteStep(_route[i], isPlace(_route[i]), false));
        }
        currentStepIndex[_shipmentId] = 0;
        return true;
    }

//__________________________________________________________________________________________________________________________________
    //Shipment process steps

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
    //DeliveryProcess

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
    //Route functions

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
    //Utils

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

    //function called by the raspberry pi to check, if the shipment exist or not
    function checkIfShipmentExists(uint256 _shipmentId) public view returns(bool) {

        if (shipmentStep[_shipmentId] == shipmentSteps.Initialized) {
            return false;
        } else {
            return true;
        }
        
    }

}