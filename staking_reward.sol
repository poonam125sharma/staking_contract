// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './tokena.sol';
import './tokenb.sol';

contract StakingReward {
    using SafeMath for uint256;
    
    TokenA public tokenAAddress;
    TokenB public tokenBAddress;
    
    struct Stake {
        uint256 amount;
        uint256 lastUpdateTime;
        uint256 reward;
    }
    
    mapping(address => Stake) public stakes;
    
    event Staked(address _user, uint256 _amount, uint256 _stakedTime);
    event Reward(address _user, uint256 _amount);
    event Withdraw(address _user, uint256 _amount);
    
    constructor(TokenA _tokenAAddress, TokenB _tokenBAddress) {
        tokenAAddress = _tokenAAddress;
        tokenBAddress = _tokenBAddress;
    }
    
    // Before staking, first Approve the staking contract 
    // so that it can transfer tokens from msg.sender to this contract
    function stake(uint256 _amount) public {
        require(_amount > 0, "Staked amount cannot be zero");
        
        require(stakes[msg.sender].amount == 0, "User already has staked");
        
        require(TokenA(tokenAAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to stake tokens");
        
        TokenA(tokenAAddress).transferFrom(msg.sender, address(this), _amount);
        
        stakes[msg.sender].lastUpdateTime = block.timestamp;
        stakes[msg.sender].amount = _amount;
        
        emit Staked(msg.sender, _amount, stakes[msg.sender].lastUpdateTime);
    }

    function reward() public returns(uint256) {
        require(stakes[msg.sender].amount > 0, "User has not staked any amount");
        
        uint256 _reward =_giveReward();
        return _reward;
    }

    function withdraw() public {
        require(stakes[msg.sender].amount > 0, "User has not staked");
        
        _giveReward();
        
        TokenA(tokenAAddress).transfer(msg.sender, stakes[msg.sender].amount);
        
        emit Withdraw(msg.sender, stakes[msg.sender].amount);
        
        delete stakes[msg.sender];
    }
    
    function _giveReward() private returns(uint256) {
        uint256 _amount = stakes[msg.sender].amount;
        
        uint256 noOfDays = ((block.timestamp).sub(stakes[msg.sender].lastUpdateTime)).div(1 days);
        
        noOfDays = (noOfDays == 0) ? 1 : noOfDays;
        uint256 _rewardedAmount = (noOfDays.mul(_amount)).div(100);
        
        if(_rewardedAmount > 0) {
            require( TokenB(tokenBAddress).balanceOf(address(this)) > _rewardedAmount, "Not enough balance to give reward");
            
            TokenB(tokenBAddress).transfer(msg.sender, _rewardedAmount);
            
            stakes[msg.sender].lastUpdateTime = block.timestamp;
            
            stakes[msg.sender].reward = (stakes[msg.sender].reward).add(_rewardedAmount);
            
            emit Reward(msg.sender, _rewardedAmount);
        }
        return _rewardedAmount;
    }
    
}
