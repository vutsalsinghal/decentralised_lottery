pragma solidity ^0.4.24;

contract NYC_BD_Lottery{
	address owner;
	uint public randomChoice;
	
	uint public lastParticipator;
	uint public timeToLottery;          // time when lottery ends (set by owner)
	uint public profitAmt;
	uint public totWinners;            // total no.of lottery winners!
	uint[] public choices;
	
	uint public buyIn;
	uint public participationFee;
	
	struct Participator{
	    address sender;
	    uint choice;
	    uint bettingTime;
	    bool profitReceived;
	}
	
	mapping (uint => Participator) participatorInfo;
	mapping (address => uint) addrToID;
	mapping (address => bool) alreadyApproved;
    
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	constructor() public{
		owner = msg.sender;
		randomChoice = 0;
		
		lastParticipator = 0;
		timeToLottery = now; //default
		profitAmt = 0;
		totWinners = 0;
		choices = [1,2,3];
		
		buyIn = 0.5 ether;
		participationFee = 0.0001 ether;
	}

	function placeBet(uint _choice) public payable{
		// Function to place bet (choose an option)
        require(now < timeToLottery, "Lottery has ended. No more bets can be placed untill timeToLottery is renewed by owner");
        require(msg.value >= buyIn+participationFee, "Amount < (Buy-in + Participation fee)");
        require(alreadyApproved[msg.sender] != true, "You've already placed your bet!");
        
        uint _participatorNo = ++ lastParticipator;
        if (_choice == choices[0]){
            participatorInfo[_participatorNo].choice = choices[0];
        } else if (_choice == choices[1]){
            participatorInfo[_participatorNo].choice = choices[1];
        }else if (_choice == choices[2]){
            participatorInfo[_participatorNo].choice = choices[2];
        }else{
            lastParticipator -= 1;
            require(1==2, "Choose valid option!");
        }
            
        participatorInfo[_participatorNo].sender = msg.sender;
        participatorInfo[_participatorNo].bettingTime = now;
        participatorInfo[_participatorNo].profitReceived = false;
        addrToID[msg.sender] = _participatorNo;
        alreadyApproved[msg.sender] = true;
    }

	function getProfits() public{
		// When the lottery ends, winners can call this function to receive their winnings
	    require(alreadyApproved[msg.sender], 'You did not participate in the lottery');
	    
	    if (profitAmt == 0){
	           calProfit(); 
	    }
	    uint _userID = addrToID[msg.sender];
	    require(!participatorInfo[_userID].profitReceived, "You've already received the profits!");
	    if (participatorInfo[_userID].choice == randomChoice){
	        if (participatorInfo[_userID].bettingTime < timeToLottery){ //Dont disburse profits to those who made bet after timeToLottery
	            (msg.sender).transfer(profitAmt);
	            participatorInfo[_userID].profitReceived = true;
	            alreadyApproved[msg.sender] = false;
            }
       }
	}
	
	function calProfit() internal{
		// Internal function to calculate the profits each winner will receive!
	    require(randomChoice != 0, "Owner has not yet set the 'winning choice'!");
	    for (uint i=1; i<lastParticipator+1; i++){
	        if (participatorInfo[i].bettingTime < timeToLottery){ // Dont include users who made bet after timeToLottery
    	        if (participatorInfo[i].choice == randomChoice){
    	            totWinners += 1;
    	        }
	        }
	    }
	    if (totWinners != 0){
	        profitAmt = totalPot() / totWinners;
	    }
	}
	
	function totalPot() view public returns(uint){
        // Function to view value in total lottery pot (in wei)
	    return buyIn * lastParticipator;
	}

	function timeLeft() view external returns(uint time_left){
	    // Function to display time left until lottery (in seconds)
	    if (now < timeToLottery){
	        return timeToLottery - now;
	    }else{
	        return 0;
	    }
	}
	
	function currentTime() view external onlyOwner returns(uint){
	    // Function to help owner set timeToLottery
	    return now;
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

	function getParticipatorInfo(uint id) view external onlyOwner returns (address senderAddr, uint choice, uint timeOfBet, bool profitReceived){
		return (participatorInfo[id].sender, participatorInfo[id].choice, participatorInfo[id].bettingTime, participatorInfo[id].profitReceived);
	}
	
	function setTimeToLottery(uint _timeToLottery) external onlyOwner{
	    // Function to set when the lottery ends!
	    timeToLottery = _timeToLottery;
	    
	    // Reset values
	    for (uint i=1; i<lastParticipator+1; i++){
	        addrToID[participatorInfo[i].sender] = 0;
	        alreadyApproved[participatorInfo[i].sender] = false;

	        participatorInfo[i].sender = 0x0;
	        participatorInfo[i].choice = 0;
	        participatorInfo[i].bettingTime = 0;
	        participatorInfo[i].profitReceived = false;
	    }
	    
	    randomChoice = 0;
	    totWinners = 0;
	    lastParticipator = 0;
	}
	
	function setWiningChoice(uint _rndChoice) external onlyOwner{
	    // Function to set the "lottery winning" choice randomly using external source (eg. Oracles)
	    require(now > timeToLottery);
	    randomChoice = _rndChoice;
	}
	
	function setAmt(uint _buyIn, uint _participationFee) external onlyOwner{
		// set buy-in and participation fee of the user
		buyIn = _buyIn;
		participationFee = _participationFee;
	}

	function transferParticipationFee() external onlyOwner{
	    // transfer participation fee to owner
	    uint _amt = participationFee * lastParticipator;
    	owner.transfer(_amt);
    }
	
	function transferEther(uint amount) external onlyOwner{
    	// transfer ether to owner
    	owner.transfer(amount);
    }

	function kill() public onlyOwner{
		selfdestruct(owner);
	}
}
