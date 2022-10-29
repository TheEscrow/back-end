# back-end

## Introduction
In this project we intend to allow anyone to post "OFFERS" to our platform, which "WORKERS" can take on to earn a previously stated amount. All the payment is handled by a smart contract.

## Core Functionality
The entire back-end is written in solidity and has the following main functions:

1. createOffer: Anyone can create an offer on our platform. This creates a struct object that includes the following variables and initiates the payment to the escrow account.
        {uint256 offerId;
        string name;
        uint256 amount;
        address owner;}
2. applyOffer: Anyone can apply for an available "OFFER" on the platform. This adds the following information to the object.
        {address worker;}
3. approveWorker: The "OWNER" of the "OFFER" can browse through the "WORKERS" that have applied for the "OFFER". He can approve one of them.
4. workFinished: Once the "WORKER" finished the "OFFER" he can set the status of the work to "FINISHED".
5. confirmWork: The "OWNER" of the "OFFER" can confirm if the work is satisfactory or not. If it is satisfactory the "WORKER" will automatically be paid out by the smart contract.

At current there are five possible states of the "OFFER":
        {OPEN,
        PROGRESS,
        FINISHED,
        DISPUTED,
        CONFIRMED}

## Future Developments
Possible improvements:
    
    1. What happens if the work is not satisfactory? Can the work be disputed?
    2. What if the payment should be handled in USDC instead of ETH.
