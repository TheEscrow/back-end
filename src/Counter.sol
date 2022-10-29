// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard{
    address public escrowAcc; //the escrow account address.
    uint256 public escrowBal; //the balance stored on the escrow account.
    uint256 public totalOffers; //the total amount offers in any state.
    uint256 public totalConfirmed; //the total amount of offers successfully closed.
    
    struct OffersStruct { //This struct contains all related information to one offer.
        uint256 offerId;
        string name;
        uint256 amount;
        address owner;
        address worker;
        Status status;
        bool confirmed;
    }
    
    mapping(uint256 => OffersStruct) private offers; //offers map will keep track of all the offers created on this marketplace.
    mapping(address => OffersStruct[]) private offersOf; //offersOf holds the items of a specific user according to his address.
    mapping(address => mapping(uint256 => bool)) public requested; //requested keeps track of every offer a worker has requested.
    mapping(uint256 => address) public ownerOf; //ownerOf keeps track of the owner of each offer.
    mapping(uint256 => Available) public isAvailable; //isAvailable keeps track of offers that have not been assigned to anyone.

    enum Status { //tracks the status of each offer. There are only 3 states.
        OPEN,
        PROGRESS,
        CONFIRMED
    }

    enum Available { NO, YES } //tracks the availibility of an offer.

    // the below executes all events triggered.
    event Action (
        uint256 Id,
        string actionType,
        Status status,
        address indexed executor
    );

    constructor() { //constructor to initiliase states
        escrowAcc = msg.sender;
        escrowBal = 0;
        totalOffers = 0;
        totalConfirmed = 0;
    }    

    function createItem(string calldata offerName) payable external returns (bool) {
        // Validating parameters
        require(bytes(offerName).length > 0, "The name of your offer cannot be empty");
        require(msg.value > 0 ether, "Offer Amount cannot be zero ethers");
    
        // Creating the offer
        uint256 offerId = totalOffers++;
        OffersStruct storage offer = offers[offerId];
        offer.offerId = offerId;
        offer.name = offerName;
        offer.amount = msg.value;
        offer.owner = msg.sender;
        offer.status = Status.OPEN;

        // Assigning to owner and stating availability
        offersOf[msg.sender].push(offer);
        ownerOf[offerId] = msg.sender;
        isAvailable[offerId] = Available.YES;
        escrowBal += msg.value;
    
        // Emitting or Logging of created Offer information
        emit Action (
            offerId,
            "OFFER CREATED",
            Status.OPEN,
            msg.sender
        );

        return true;
    }

    function acceptOffer(uint256 offer) public {
        number = newNumber;
    }

    function assignWorker(uint256 offer) public {
        number = newNumber;
    }

    function approveJob(uint256 offer) public payable {
        number = newNumber;
    }
}
