// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Simple ERC-20 Token Base
 * @dev Minimal ERC-20 implementation for our chemical tokens
 */
contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        totalSupply = _initialSupply; // No decimals multiplication
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
    
    // Special functions for the reaction manager
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner can mint");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        require(msg.sender == owner, "Only owner can burn");
        require(balanceOf[from] >= amount, "Insufficient balance to burn");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

/**
 * @title H2EquilibriumSystem
 * @dev Models the reaction: 2H+ ⇌ H2
 * Combines H+ tokens, reaction management, and H2 tokens in one contract
 */
contract H2EquilibriumSystem {
    
    // Token contracts
    SimpleToken public hPlusToken;
    SimpleToken public h2Token;
    
    // Reaction parameters
    uint256 public constant REACTION_RATIO = 2; // 2 H+ → 1 H2
    uint256 public forwardReactionCount;
    uint256 public reverseReactionCount;
    
    // Events
    event ForwardReaction(address indexed user, uint256 hPlusConsumed, uint256 h2Produced, string message);
    event ReverseReaction(address indexed user, uint256 h2Consumed, uint256 hPlusProduced, string message);
    
    constructor() {
        // Deploy token contracts - this contract becomes the owner
        hPlusToken = new SimpleToken("Hydrogen Ion", "H+", 1000);
        h2Token = new SimpleToken("Hydrogen Gas", "H2", 0);
        
        // Transfer initial H+ tokens to the deployer
        hPlusToken.transfer(msg.sender, 1000);
    }
    
    /**
     * @dev Forward reaction: 2H+ → H2
     * User must have at least 2 H+ tokens
     */
    function combineHydrogen() external {
        uint256 userHPlusBalance = hPlusToken.balanceOf(msg.sender);
        require(userHPlusBalance >= REACTION_RATIO, "Need at least 2 H+ tokens");
        
        uint256 hPlusToConsume = REACTION_RATIO;
        uint256 h2ToProduce = 1;
        
        // Burn 2 H+ tokens
        hPlusToken.burn(msg.sender, hPlusToConsume);
        
        // Mint 1 H2 token
        h2Token.mint(msg.sender, h2ToProduce);
        
        forwardReactionCount++;
        emit ForwardReaction(msg.sender, hPlusToConsume, h2ToProduce, 
            "Two hydrogen ions (H+) combined to form one hydrogen molecule (H2)");
    }
    
    /**
     * @dev Reverse reaction: H2 → 2H+
     * User must have at least 1 H2 token
     */
    function splitHydrogen() external {
        uint256 userH2Balance = h2Token.balanceOf(msg.sender);
        require(userH2Balance >= 1, "Need at least 1 H2 token");
        
        uint256 h2ToConsume = 1;
        uint256 hPlusToProduce = REACTION_RATIO;
        
        // Burn 1 H2 token
        h2Token.burn(msg.sender, h2ToConsume);
        
        // Mint 2 H+ tokens
        hPlusToken.mint(msg.sender, hPlusToProduce);
        
        reverseReactionCount++;
        emit ReverseReaction(msg.sender, h2ToConsume, hPlusToProduce, 
            "One hydrogen molecule (H2) split into two hydrogen ions (H+)");
    }
    
    /**
     * @dev Get user's token balances
     */
    function getUserBalances(address user) external view returns (uint256 hPlusBalance, uint256 h2Balance) {
        hPlusBalance = hPlusToken.balanceOf(user);
        h2Balance = h2Token.balanceOf(user);
    }
    
    /**
     * @dev Get reaction statistics
     */
    function getReactionStats() external view returns (uint256 forward, uint256 reverse, uint256 totalHPlus, uint256 totalH2) {
        forward = forwardReactionCount;
        reverse = reverseReactionCount;
        totalHPlus = hPlusToken.totalSupply();
        totalH2 = h2Token.totalSupply();
    }
    
    /**
     * @dev Get token contract addresses
     */
    function getTokenAddresses() external view returns (address hPlusAddr, address h2Addr) {
        hPlusAddr = address(hPlusToken);
        h2Addr = address(h2Token);
    }
}

// DEPLOYMENT AND TESTING INSTRUCTIONS:
//
// 1. DEPLOY:
//    - Open Remix IDE (remix.ethereum.org)
//    - Create new file: H2System.sol
//    - Copy this entire code
//    - Compile with Solidity 0.8.19
//    - Deploy H2EquilibriumSystem contract
//
// 2. INITIAL STATE:
//    - Deployer gets 1000 H+ tokens
//    - 0 H2 tokens exist initially
//    - Call getUserBalances(YOUR_ADDRESS) to verify
//
// 3. TEST FORWARD REACTION (2H+ → H2):
//    - Call combineHydrogen()
//    - Should consume 2 H+ and produce 1 H2
//    - Check balances with getUserBalances()
//    - Check stats with getReactionStats()
//
// 4. TEST REVERSE REACTION (H2 → 2H+):
//    - Call splitHydrogen()
//    - Should consume 1 H2 and produce 2 H+
//    - Verify balances changed correctly
//
// 5. EXPECTED BEHAVIOR:
//    - Start: 1000 H+, 0 H2
//    - After combineHydrogen(): 998 H+, 1 H2
//    - After splitHydrogen(): 1000 H+, 0 H2
//
// 6. ERROR TESTING:
//    - Try combineHydrogen() with <2 H+ tokens
//    - Try splitHydrogen() with 0 H2 tokens
//    - Should revert with appropriate messages
