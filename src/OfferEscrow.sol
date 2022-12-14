// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OfferEscrow is ReentrancyGuard {
    address public escrowAcc; //the escrow account address.
    uint256 public escrowBal; //the balance stored on the escrow account.
    uint256 public totalOffers; //the total amount offers in any state.
    uint256 public totalConfirmed; //the total amount of offers successfully closed.

    struct OffersStruct {
        //This struct contains all related information to one offer.
        uint256 offerId;
        string name;
        uint256 amount;
        address owner;
        address[] applicants;
        address worker;
        Status status;
        bool provided;
        bool confirmed;
    }

    mapping(uint256 => OffersStruct) private offers; //offers map will keep track of all the offers created on this marketplace.
    mapping(address => OffersStruct[]) private offersOf; //offersOf holds the items of a specific user according to his address.
    mapping(address => OffersStruct[]) private applicationsOf; //applicationsOf holds the applications of a specific user according to his address.
    mapping(address => mapping(uint256 => bool)) public requested; //requested keeps track of every offer a worker has requested.
    mapping(uint256 => address) public ownerOf; //ownerOf keeps track of the owner of each offer.
    mapping(uint256 => Available) public isAvailable; //isAvailable keeps track of offers that have not been assigned to anyone.

    enum Status {
        //tracks the status of each offer. There are only 3 states.
        OPEN,
        PROGRESS,
        FINISHED,
        DISPUTED,
        CONFIRMED
    }

    enum Available {
        NO,
        YES
    } //tracks the availibility of an offer.

    // the below executes all events triggered.
    event Action(
        uint256 offerId,
        string actionType,
        Status status,
        address indexed executor
    );

    //constructor to initiliase states
    constructor() {
        escrowAcc = msg.sender;
        escrowBal = 0;
        totalOffers = 0;
        totalConfirmed = 0;
    }

    // With this function anyone can create an Offer on the platform. This also initiates the escrow payment.
    function createOffer(string calldata offerName)
        external
        payable
        returns (bool)
    {
        // Validating parameters
        require(
            bytes(offerName).length > 0,
            "The name of your offer cannot be empty"
        );
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
        emit Action(offerId, "OFFER CREATED", Status.OPEN, msg.sender);

        return true;
    }

    //This simply returns an array of all the offers posted.
    function getOffers() external view returns (OffersStruct[] memory props) {
        props = new OffersStruct[](totalOffers);

        for (uint256 i = 0; i < totalOffers; i++) {
            props[i] = offers[i];
        }
    }

    //This simply returns an offer based on the offerID input.
    function getOffer(uint256 offerId)
        external
        view
        returns (OffersStruct memory)
    {
        return offers[offerId];
    }

    //This returns all offers an owner has created. Anyone can call this and see his/her created offers.
    function myOffers() external view returns (OffersStruct[] memory) {
        return offersOf[msg.sender];
    }

    //This simply returns all workers that applied to a specific offerID input.
    function getApplicants(uint256 offerId) public view returns(address[] memory) { 
        return offers[offerId].applicants; 
        }

    //This returns all applications a worker has done. Anyone can call this and see the offers he/she applied for.
    function myApplications() external view returns (OffersStruct[] memory) {
        return applicationsOf[msg.sender];
    }

    //With this function anyone can apply for an offer on the platform.
    function applyOffer(uint256 offerId) external returns (bool) {
        // Perfoms essential record validation
        require(
            msg.sender != ownerOf[offerId],
            "Owner cannot apply for his own Offer"
        );
        require(isAvailable[offerId] == Available.YES, "Offer not available");
        //pull offer object
        OffersStruct storage offer = offers[offerId];
        //push applicant into applicant array in offer struct
        offers[offerId].applicants.push(msg.sender);
        //push offer into applicant mapping
        applicationsOf[msg.sender].push(offer);
        // Places request on an item
        requested[msg.sender][offerId] = true;

        emit Action(offerId, "REQUESTED", Status.OPEN, msg.sender);
        return true;
    }

    // This function allows the owner to approve one of the workers that applied for their offer.
    function approveWorker(uint256 offerId, address worker)
        external
        returns (bool)
    {
        // Checks for essential requirement
        require(msg.sender == ownerOf[offerId], "Only owner allowed");
        require(isAvailable[offerId] == Available.YES, "Item not available");
        require(
            requested[worker][offerId],
            "Worker has not applied for the offer"
        );

        // Assigns an offer to a worker
        isAvailable[offerId] == Available.NO;
        offers[offerId].status = Status.PROGRESS;
        offers[offerId].worker = worker;

        emit Action(offerId, "APPROVED", Status.PROGRESS, msg.sender);

        return true;
    }

    //This function allows the worker to submit their work as finished.
    function workFinished(uint256 offerId) external returns (bool) {
        // Checks for essential conditions
        require(
            msg.sender == offers[offerId].worker,
            "The offer has not been awarded to you"
        );
        require(!offers[offerId].provided, "Work has already been provided");
        require(!offers[offerId].confirmed, "Work has already been confirmed");

        // Marks work as provided
        offers[offerId].provided = true;
        offers[offerId].status = Status.FINISHED;

        emit Action(
            offerId,
            "WORK HAS BEEN COMPLETED",
            Status.FINISHED,
            msg.sender
        );
        return true;
    }

    // This function allows the owner to confirm the work of the worker and finalise payout.
    function confirmWork(uint256 offerId, bool provided)
        external
        returns (bool)
    {
        // Checks vital condition
        require(msg.sender == ownerOf[offerId], "Only owner allowed!");
        require(offers[offerId].provided, "Work has not been done!");
        // Indicates delievery status
        if (provided) {
            // Pays the provider
            payTo(offers[offerId].worker, (offers[offerId].amount));

            // Recalibrates records
            escrowBal -= offers[offerId].amount;
            offers[offerId].confirmed = true;

            // Marks as confirmed
            offers[offerId].status = Status.CONFIRMED;
            emit Action(offerId, "CONFIRMED", Status.CONFIRMED, msg.sender);
            totalConfirmed++;
        } else {
            // Marks as disputted
            offers[offerId].status = Status.DISPUTED;
            emit Action(offerId, "DISPUTED", Status.DISPUTED, msg.sender);
        }
        return true;
    }

    // Takes care of the payout process
    function payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}