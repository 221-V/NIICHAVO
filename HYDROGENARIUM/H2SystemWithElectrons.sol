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
        totalSupply = _initialSupply;
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
 * @dev Models the complete reaction: 2H+ + 2e⁻ ⇌ H2
 * Includes intermediate hydrogen atoms: H+ + e⁻ ⇌ H, then 2H ⇌ H2
 */
contract H2EquilibriumSystem {
    
    // Token contracts
    SimpleToken public hPlusToken;    // H+ ions
    SimpleToken public electronToken; // e⁻ electrons
    SimpleToken public hAtomToken;    // H neutral atoms
    SimpleToken public h2Token;       // H2 molecules
    
    // Reaction counters
    uint256 public ionizationCount;        // H → H+ + e⁻
    uint256 public neutralizationCount;    // H+ + e⁻ → H
    uint256 public atomCombineCount;       // 2H → H2
    uint256 public moleculeSplitCount;     // H2 → 2H
    
    // Events with descriptive messages
    event Ionization(address indexed user, uint256 hAtomsConsumed, uint256 hPlusProduced, uint256 electronsProduced, string message);
    event Neutralization(address indexed user, uint256 hPlusConsumed, uint256 electronsConsumed, uint256 hAtomsProduced, string message);
    event AtomCombination(address indexed user, uint256 hAtomsConsumed, uint256 h2Produced, string message);
    event MoleculeSplit(address indexed user, uint256 h2Consumed, uint256 hAtomsProduced, string message);
    
    constructor() {
        // Deploy all token contracts
        hPlusToken = new SimpleToken("Hydrogen Ion", "H+", 1000);
        electronToken = new SimpleToken("Electron", "e-", 1000);
        hAtomToken = new SimpleToken("Hydrogen Atom", "H", 0);
        h2Token = new SimpleToken("Hydrogen Molecule", "H2", 0);
        
        // Transfer initial tokens to the deployer
        hPlusToken.transfer(msg.sender, 1000);
        electronToken.transfer(msg.sender, 1000);
    }
    
    /**
     * @dev Neutralization: H+ + e⁻ → H
     * Combines a hydrogen ion with an electron to form a neutral hydrogen atom
     */
    function neutralizeIon() external {
        require(hPlusToken.balanceOf(msg.sender) >= 1, "Need at least 1 H+ token");
        require(electronToken.balanceOf(msg.sender) >= 1, "Need at least 1 e- token");
        
        // Burn 1 H+ and 1 e⁻
        hPlusToken.burn(msg.sender, 1);
        electronToken.burn(msg.sender, 1);
        
        // Mint 1 H atom
        hAtomToken.mint(msg.sender, 1);
        
        neutralizationCount++;
        emit Neutralization(msg.sender, 1, 1, 1, 
            "One hydrogen ion (H+) captured one electron (e-) to form one neutral hydrogen atom (H)");
    }
    
    /**
     * @dev Ionization: H → H+ + e⁻
     * Splits a neutral hydrogen atom into a hydrogen ion and electron
     */
    function ionizeAtom() external {
        require(hAtomToken.balanceOf(msg.sender) >= 1, "Need at least 1 H atom token");
        
        // Burn 1 H atom
        hAtomToken.burn(msg.sender, 1);
        
        // Mint 1 H+ and 1 e⁻
        hPlusToken.mint(msg.sender, 1);
        electronToken.mint(msg.sender, 1);
        
        ionizationCount++;
        emit Ionization(msg.sender, 1, 1, 1, 
            "One hydrogen atom (H) ionized into one hydrogen ion (H+) and one electron (e-)");
    }
    
    /**
     * @dev Atom combination: 2H → H2
     * Combines two hydrogen atoms to form a hydrogen molecule
     */
    function combineAtoms() external {
        require(hAtomToken.balanceOf(msg.sender) >= 2, "Need at least 2 H atom tokens");
        
        // Burn 2 H atoms
        hAtomToken.burn(msg.sender, 2);
        
        // Mint 1 H2 molecule
        h2Token.mint(msg.sender, 1);
        
        atomCombineCount++;
        emit AtomCombination(msg.sender, 2, 1, 
            "Two hydrogen atoms (H) combined to form one hydrogen molecule (H2)");
    }
    
    /**
     * @dev Molecule split: H2 → 2H
     * Splits a hydrogen molecule into two hydrogen atoms
     */
    function splitMolecule() external {
        require(h2Token.balanceOf(msg.sender) >= 1, "Need at least 1 H2 molecule token");
        
        // Burn 1 H2 molecule
        h2Token.burn(msg.sender, 1);
        
        // Mint 2 H atoms
        hAtomToken.mint(msg.sender, 2);
        
        moleculeSplitCount++;
        emit MoleculeSplit(msg.sender, 1, 2, 
            "One hydrogen molecule (H2) split into two hydrogen atoms (H)");
    }
    
    /**
     * @dev Complete forward reaction: 2H+ + 2e⁻ → H2
     * Performs the full reaction in one step
     */
    function completeForwardReaction() external {
        require(hPlusToken.balanceOf(msg.sender) >= 2, "Need at least 2 H+ tokens");
        require(electronToken.balanceOf(msg.sender) >= 2, "Need at least 2 e- tokens");
        
        // Burn 2 H+ and 2 e⁻
        hPlusToken.burn(msg.sender, 2);
        electronToken.burn(msg.sender, 2);
        
        // Mint 1 H2 molecule
        h2Token.mint(msg.sender, 1);
        
        neutralizationCount += 2; // Equivalent to 2 neutralization steps
        atomCombineCount++; // Plus 1 atom combination
        
        emit Neutralization(msg.sender, 2, 2, 0, "Complete reaction: 2H+ + 2e- => H2 (two hydrogen ions and two electrons formed one hydrogen molecule)");
    }
    
    /**
     * @dev Complete reverse reaction: H2 → 2H+ + 2e⁻
     * Performs the full reverse reaction in one step
     */
    function completeReverseReaction() external {
        require(h2Token.balanceOf(msg.sender) >= 1, "Need at least 1 H2 molecule token");
        
        // Burn 1 H2 molecule
        h2Token.burn(msg.sender, 1);
        
        // Mint 2 H+ and 2 e⁻
        hPlusToken.mint(msg.sender, 2);
        electronToken.mint(msg.sender, 2);
        
        moleculeSplitCount++; // 1 molecule split
        ionizationCount += 2; // Equivalent to 2 ionization steps
        
        emit Ionization(msg.sender, 0, 2, 2, "Complete reverse reaction: H2 => 2H+ + 2e- (one hydrogen molecule split into two hydrogen ions and two electrons)");
    }
    
    /**
     * @dev Get user's token balances for all species
     */
    function getUserBalances(address user) external view returns (
        uint256 hPlusBalance, 
        uint256 electronBalance, 
        uint256 hAtomBalance, 
        uint256 h2Balance
    ) {
        hPlusBalance = hPlusToken.balanceOf(user);
        electronBalance = electronToken.balanceOf(user);
        hAtomBalance = hAtomToken.balanceOf(user);
        h2Balance = h2Token.balanceOf(user);
    }
    
    /**
     * @dev Get reaction statistics
     */
    function getReactionStats() external view returns (
        uint256 ionizations,
        uint256 neutralizations, 
        uint256 atomCombinations,
        uint256 moleculeSplits,
        uint256 totalHPlus,
        uint256 totalElectrons,
        uint256 totalHAtoms,
        uint256 totalH2
    ) {
        ionizations = ionizationCount;
        neutralizations = neutralizationCount;
        atomCombinations = atomCombineCount;
        moleculeSplits = moleculeSplitCount;
        totalHPlus = hPlusToken.totalSupply();
        totalElectrons = electronToken.totalSupply();
        totalHAtoms = hAtomToken.totalSupply();
        totalH2 = h2Token.totalSupply();
    }
    
    /**
     * @dev Get all token contract addresses
     */
    function getTokenAddresses() external view returns (
        address hPlusAddr, 
        address electronAddr, 
        address hAtomAddr, 
        address h2Addr
    ) {
        hPlusAddr = address(hPlusToken);
        electronAddr = address(electronToken);
        hAtomAddr = address(hAtomToken);
        h2Addr = address(h2Token);
    }
}

// DEPLOYMENT AND TESTING INSTRUCTIONS:
//
// 1. DEPLOY:
//    - Open Remix IDE (remix.ethereum.org)
//    - Create new file: H2SystemWithElectrons.sol
//    - Copy this entire code
//    - Compile with Solidity 0.8.19
//    - Deploy H2EquilibriumSystem contract
//
// 2. INITIAL STATE:
//    - Deployer gets 1000 H+ tokens and 1000 e- tokens
//    - 0 H atoms and 0 H2 molecules initially
//    - Call getUserBalances(YOUR_ADDRESS) to verify
//
// 3. TEST INDIVIDUAL REACTIONS:
//    - neutralizeIon(): H+ + e- → H (need 1 H+ and 1 e-)
//    - ionizeAtom(): H → H+ + e- (need 1 H atom)
//    - combineAtoms(): 2H → H2 (need 2 H atoms)
//    - splitMolecule(): H2 → 2H (need 1 H2 molecule)
//
// 4. TEST COMPLETE REACTIONS:
//    - completeForwardReaction(): 2H+ + 2e- → H2 (need 2 H+ and 2 e-)
//    - completeReverseReaction(): H2 → 2H+ + 2e- (need 1 H2)
//
// 5. EXAMPLE WORKFLOW:
//    - Start: 1000 H+, 1000 e-, 0 H, 0 H2
//    - neutralizeIon() twice: 998 H+, 998 e-, 2 H, 0 H2
//    - combineAtoms(): 998 H+, 998 e-, 0 H, 1 H2
//    - splitMolecule(): 998 H+, 998 e-, 2 H, 0 H2
//    - ionizeAtom() twice: 1000 H+, 1000 e-, 0 H, 0 H2
//
// 6. MASS CONSERVATION:
//    - Total protons always conserved (H+ + H + 2×H2 = constant)
//    - Total electrons always conserved (e- + H + 2×H2 = constant)
//    - Charge always balanced
