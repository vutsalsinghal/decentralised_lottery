pragma solidity ^0.4.24;

import "./safeMath.sol";

/**
 * @title DecentralisedLottery
 * @notice This is a type of coin flip lottery (instead of Lotto lottery).
           But instead of binary coin-flip, it can ternary, quaternary, ..., etc.
 * @dev A completely decentralised lottery
 */
 contract DecentralisedLottery{

    // library declaration
    using SafeMath for uint256;
    
    // ------------------ Variables -----------------\\
    
    address owner;
    uint public winningChoice;                                       // randomly generated choice (after lottery ends)
    uint public timeToLottery;                                       // time when lottery ends (set by owner)
    uint public encashDuration;                                      // duration (after lottery ended) during which 
                                                                          // participants can get their profits (default: 1 day)
    uint public lastParticipator;                                    // keep track of total participants
    uint public totWinners;                                          // total no.of lottery winners!
    uint public profitAmt;                                           // (total pot)/(total winners)
    uint[] public choices;                                           // options from which participants can choose
    uint public buyIn;                                               // minimum amount to be eligible to participate
    uint public participationFee;                                    // owners cut
    
    struct Participator{
        address sender;
        uint choice;
        uint bettingTime;
        bool profitReceived;
    }
    
    // ------------------ Mappings -----------------\\
    
    mapping (uint => Participator) participatorInfo;
    mapping (address => uint) addrToID;
    mapping (address => bool) alreadyApproved;
    
    // ------------------ Modifiers -----------------\\
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier lotteryOnGoing {
        require(now < timeToLottery);
        _;
    }

    modifier lotteryEnded {
        require(now >= timeToLottery);
        _;
    }

    modifier encashDurationOngoing {
        require(now >= timeToLottery && now < encashDuration);
        _;
    }

    modifier encashDurationEnded {
        require(now >= encashDuration);
        _;
    }
    
    // ------------------ Constructor -----------------\\
    
    constructor() public{
        owner = msg.sender;
        winningChoice = 0;
        timeToLottery = now;
        encashDuration = now.add(24 hours);
        lastParticipator = 0;
        totWinners = 0;
        profitAmt = 0;
        choices = [1,2,3];
        buyIn = 0.5 ether;
        participationFee = 0.0001 ether;
    }

    // ------------------ Public/External functions -----------------\\
    
    function placeBet(uint _choice) public lotteryOnGoing payable{
    // Function to place bet (choose an option)
        require(msg.value >= buyIn.add(participationFee), "Amount < (Buy-in + Participation fee)");
        require(alreadyApproved[msg.sender] != true, "You've already placed your bet!");

        lastParticipator = lastParticipator.add(1);                             // using safemath syntax
        uint _participatorNo = lastParticipator;
        if (_choice == choices[0]){
            participatorInfo[_participatorNo].choice = choices[0];
        } else if (_choice == choices[1]){
            participatorInfo[_participatorNo].choice = choices[1];
        }else if (_choice == choices[2]){
            participatorInfo[_participatorNo].choice = choices[2];
        }else{
            lastParticipator = lastParticipator.sub(1);                         // using safemath syntax
            require(1==2, "Choose valid option!");                              // Throw error
        }

        participatorInfo[_participatorNo].sender = msg.sender;
        participatorInfo[_participatorNo].bettingTime = now;
        participatorInfo[_participatorNo].profitReceived = false;
        addrToID[msg.sender] = _participatorNo;
        alreadyApproved[msg.sender] = true;
    }

    function getParticipatorInfo() view public returns (address senderAddr, uint choice, uint timeOfBet, bool profitReceived){
    // Each participant can view his and only his info!
        uint _userID = addrToID[msg.sender];
        if (msg.sender == participatorInfo[_userID].sender){
            return (participatorInfo[_userID].sender, participatorInfo[_userID].choice, participatorInfo[_userID].bettingTime, participatorInfo[_userID].profitReceived);
        }else{
            // Not authorised!
            return (msg.sender,0,0,false);
        }
    }

    function getProfits() public encashDurationOngoing{
    // When the lottery ends, winners can call this function to receive their winnings
        require(alreadyApproved[msg.sender], 'You did not participate in the lottery');

        if (profitAmt == 0) calProfit();                                        // Just making sure! (already called for the 1st time inside setWiningChoice() by owner)
         
        uint _userID = addrToID[msg.sender];
        require(!participatorInfo[_userID].profitReceived, "You've already received the profits!");
        if (participatorInfo[_userID].choice == winningChoice){
            if (participatorInfo[_userID].bettingTime < timeToLottery){         // Dont disburse profits to those who made bet after timeToLottery
                (msg.sender).transfer(profitAmt);
                participatorInfo[_userID].profitReceived = true;
                alreadyApproved[msg.sender] = false;
            }
        }
    }
    
    function totalPot() view public returns(uint){
    // Function to view value in total lottery pot (in wei)
        return buyIn.mul(lastParticipator);
    }

    function timeLeft() view external lotteryOnGoing returns(uint time_left){
    // Function to display time (in seconds) left until lottery ends
        if (now < timeToLottery){
            return timeToLottery.sub(now);
        }else{
            return 0;
        }
    }

    function timeLeftToEncash() view external encashDurationOngoing returns(uint time_left){
        // Function to display time (in seconds) left until participants can get their profits
        if (now < encashDuration){
            return encashDuration.sub(now);
        }else{
            return 0;
        }
    }

    // ------------------ OnlyOwner/Internal functions -----------------\\
    
    function calProfit() internal{
    // Internal function to calculate the profits each winner will receive!
        require(winningChoice != 0, "Owner has not yet set the 'winning choice'!");
        for (uint i=1; i<lastParticipator+1; i++){
            if (participatorInfo[i].bettingTime < timeToLottery){               // Dont include users who made bet after timeToLottery
                if (participatorInfo[i].choice == winningChoice){
                    totWinners = totWinners.add(1);                             // using safemath syntax
                }
            }
        }
        if (totWinners != 0) profitAmt = totalPot().div(totWinners);            // using safemath syntax
    }

    function currentTime() view external onlyOwner returns(uint){
    // Function to help owner set timeToLottery
        return now;
    }

    function getParticipatorInfo(uint id) view external onlyOwner returns (address senderAddr, uint choice, uint timeOfBet, bool profitReceived){
        return (participatorInfo[id].sender, participatorInfo[id].choice, participatorInfo[id].bettingTime, participatorInfo[id].profitReceived);
    }

    function setTimeToLottery(uint _timeToLottery) external onlyOwner lotteryEnded{
    // Function to (re)set "when" the lottery ends!
        timeToLottery = _timeToLottery;
            
        // Reset values
        for (uint i=1; i<lastParticipator+1; i++){
            addrToID[participatorInfo[i].sender] = 0;
            alreadyApproved[participatorInfo[i].sender] = false;

            delete participatorInfo[i];
        }
            
        winningChoice = 0;
        totWinners = 0;
        lastParticipator = 0;
    }
        
    function setWiningChoice(uint _randomChoice) external onlyOwner encashDurationOngoing{
    // Function to set the "lottery winning" choice randomly using external source (eg. Oracles)
        winningChoice = _randomChoice;
        encashDuration = timeToLottery.add(24 hours);                           // start the encash duration

        // call function to calculate profits
        if (profitAmt == 0) calProfit();
    }

    function setEncashDuration(uint _newDuration) external onlyOwner encashDurationOngoing{
    // Function to change encash duration (if need be)      
        encashDuration = _newDuration;
    }
        
    function transferParticipationFee() external onlyOwner lotteryEnded{
    // transfer participation fee to owner
        uint _amt = participationFee * lastParticipator;
        owner.transfer(_amt);
    }

    function setAmt(uint _buyIn, uint _participationFee) external onlyOwner lotteryEnded{
    // set buy-in and participation fee of the user
        buyIn = _buyIn;
        participationFee = _participationFee;
    }

    function transferEther(uint amount) external onlyOwner lotteryEnded{
    // transfer ether to owner
        owner.transfer(amount);
    }

    function kill() public onlyOwner{
    // destroy contract
        selfdestruct(owner);
    }
}
