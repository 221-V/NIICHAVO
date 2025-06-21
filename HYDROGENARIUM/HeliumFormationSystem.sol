// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Simple ERC-20 Token Base
 * @dev Minimal ERC-20 implementation for our nuclear particle tokens
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
 * @title HeliumFormationSystem
 * @dev Models nuclear processes leading to helium formation
 * Primary pathway: 4 H → He-4 + 2 e+ + 2 νe (pp-chain simplified)
 * Also includes: 2 H → D + e+ + νe, D + H → He-3 + γ, He-3 + He-3 → He-4 + 2 H
 */
contract HeliumFormationSystem {
    
    // Token contracts for nuclear particles
    SimpleToken public protonToken;        // H (protons/hydrogen nuclei)
    SimpleToken public deuteriumToken;     // D (deuterium nuclei)
    SimpleToken public helium3Token;       // He-3 nuclei
    SimpleToken public helium4Token;       // He-4 nuclei (alpha particles)
    SimpleToken public positronToken;      // e+ (positrons)
    SimpleToken public neutrinoToken;      // ve (electron neutrinos)
    SimpleToken public gammaToken;         // y (gamma rays/photons)
    
    // Nuclear reaction counters
    uint256 public ppFusionCount;          // p + p → D + e+ + νe
    uint256 public pdFusionCount;          // D + p → He-3 + γ
    uint256 public he3FusionCount;         // He-3 + He-3 → He-4 + 2p
    uint256 public completePPChainCount;   // 4 H → He-4 + 2 e+ + 2 νe
    uint256 public alphaDecayCount;        // He-4 → 2 D (reverse, artificial)
    
    // Energy released tracking (in arbitrary units)
    uint256 public totalEnergyReleased;
    
    // Events with physics descriptions
    event PPFusion(address indexed user, uint256 protonsConsumed, uint256 deuteriumProduced, 
                   uint256 positronsProduced, uint256 neutrinosProduced, string message);
    event PDFusion(address indexed user, uint256 deuteriumConsumed, uint256 protonsConsumed, 
                   uint256 helium3Produced, uint256 gammasProduced, string message);
    event He3Fusion(address indexed user, uint256 helium3Consumed, uint256 helium4Produced, 
                    uint256 protonsProduced, string message);
    event CompletePPChain(address indexed user, uint256 protonsConsumed, uint256 helium4Produced, 
                          uint256 positronsProduced, uint256 neutrinosProduced, uint256 energyReleased, string message);
    event AlphaDecay(address indexed user, uint256 helium4Consumed, uint256 deuteriumProduced, string message);
    
    constructor() {
        // Deploy all particle token contracts
        protonToken = new SimpleToken("Proton", "H", 10000);        // Start with many protons
        deuteriumToken = new SimpleToken("Deuterium", "D", 0);      // No deuterium initially
        helium3Token = new SimpleToken("Helium-3", "He3", 0);      // No He-3 initially
        helium4Token = new SimpleToken("Helium-4", "He4", 0);      // No He-4 initially
        positronToken = new SimpleToken("Positron", "e+", 0);      // No positrons initially
        neutrinoToken = new SimpleToken("Neutrino", "ve", 0);      // No neutrinos initially
        gammaToken = new SimpleToken("Gamma Ray", "y", 0);         // No gamma rays initially
        
        // Transfer initial protons to the deployer (simulating hydrogen-rich environment)
        protonToken.transfer(msg.sender, 10000);
    }
    
    /**
     * @dev Proton-Proton fusion: p + p → D + e+ + νe
     * First step of the pp-chain, converts two protons to deuterium
     * This is the slowest step in stellar nucleosynthesis
     */
    function ppFusion() external {
        require(protonToken.balanceOf(msg.sender) >= 2, "Need at least 2 protons");
        
        // Burn 2 protons
        protonToken.burn(msg.sender, 2);
        
        // Produce 1 deuterium, 1 positron, 1 neutrino
        deuteriumToken.mint(msg.sender, 1);
        positronToken.mint(msg.sender, 1);
        neutrinoToken.mint(msg.sender, 1);
        
        ppFusionCount++;
        totalEnergyReleased += 1; // 1.44 MeV in reality
        
        emit PPFusion(msg.sender, 2, 1, 1, 1, 
            "Two protons fused via weak nuclear force: p + p -> D + e+ + ve (deuterium formation with positron and neutrino emission)");
    }
    
    /**
     * @dev Proton-Deuterium fusion: D + p → He-3 + γ
     * Second step of pp-chain, much faster than pp fusion
     */
    function pdFusion() external {
        require(deuteriumToken.balanceOf(msg.sender) >= 1, "Need at least 1 deuterium nucleus");
        require(protonToken.balanceOf(msg.sender) >= 1, "Need at least 1 proton");
        
        // Burn 1 deuterium and 1 proton
        deuteriumToken.burn(msg.sender, 1);
        protonToken.burn(msg.sender, 1);
        
        // Produce 1 He-3 and 1 gamma ray
        helium3Token.mint(msg.sender, 1);
        gammaToken.mint(msg.sender, 1);
        
        pdFusionCount++;
        totalEnergyReleased += 5; // 5.49 MeV in reality
        
        emit PDFusion(msg.sender, 1, 1, 1, 1, 
            "Deuterium captured proton via strong nuclear force: D + p -> He-3 + y (helium-3 formation with gamma ray emission)");
    }
    
    /**
     * @dev Helium-3 fusion: He-3 + He-3 → He-4 + 2p
     * Final step of pp-I branch, produces stable helium-4
     */
    function he3Fusion() external {
        require(helium3Token.balanceOf(msg.sender) >= 2, "Need at least 2 He-3 nuclei");
        
        // Burn 2 He-3 nuclei
        helium3Token.burn(msg.sender, 2);
        
        // Produce 1 He-4 and 2 protons
        helium4Token.mint(msg.sender, 1);
        protonToken.mint(msg.sender, 2);
        
        he3FusionCount++;
        totalEnergyReleased += 12; // 12.86 MeV in reality
        
        emit He3Fusion(msg.sender, 2, 1, 2, 
            "Two helium-3 nuclei fused: He-3 + He-3 -> He-4 + 2p (stable helium-4 formation, recycling protons)");
    }
    
    /**
     * @dev Complete PP-Chain: 4 H → He-4 + 2 e+ + 2 νe
     * Simulates the complete proton-proton chain in one step
     * Net result: 4 protons become 1 helium-4 nucleus
     */
    function completePPChain() external {
        require(protonToken.balanceOf(msg.sender) >= 4, "Need at least 4 protons for complete pp-chain");
        
        // Burn 4 protons
        protonToken.burn(msg.sender, 4);
        
        // Produce 1 He-4, 2 positrons, 2 neutrinos
        helium4Token.mint(msg.sender, 1);
        positronToken.mint(msg.sender, 2);
        neutrinoToken.mint(msg.sender, 2);
        
        // Update all relevant counters (net effect)
        completePPChainCount++;
        totalEnergyReleased += 26; // 26.73 MeV total
        
        emit CompletePPChain(msg.sender, 4, 1, 2, 2, 26, 
            "Complete pp-chain: 4H -> He-4 + 2e+ + 2ve (nuclear fusion converting hydrogen to helium, the primary energy source in stars)");
    }
    
    /**
     * @dev Alpha decay simulation: He-4 → 2 D
     * Artificial reverse process for educational purposes
     * (Real alpha decay would be He-4 → 2p + 2n, but we simplify)
     */
    function alphaDecay() external {
        require(helium4Token.balanceOf(msg.sender) >= 1, "Need at least 1 He-4 nucleus");
        
        // Burn 1 He-4
        helium4Token.burn(msg.sender, 1);
        
        // Produce 2 deuterium (simplified - real would be 2p + 2n)
        deuteriumToken.mint(msg.sender, 2);
        
        alphaDecayCount++;
        
        emit AlphaDecay(msg.sender, 1, 2, 
            "Helium-4 nucleus split into deuterium nuclei (simplified educational model)");
    }
    
    /**
     * @dev Emergency proton injection (for testing)
     * Simulates hydrogen gas injection into the system
     */
    function injectHydrogen(uint256 amount) external {
        require(amount <= 1000, "Maximum 1000 protons per injection");
        protonToken.mint(msg.sender, amount);
    }
    
    /**
     * @dev Get user's particle balances
     */
    function getUserBalances(address user) external view returns (
        uint256 protons,
        uint256 deuterium, 
        uint256 helium3,
        uint256 helium4,
        uint256 positrons,
        uint256 neutrinos,
        uint256 gammas
    ) {
        protons = protonToken.balanceOf(user);
        deuterium = deuteriumToken.balanceOf(user);
        helium3 = helium3Token.balanceOf(user);
        helium4 = helium4Token.balanceOf(user);
        positrons = positronToken.balanceOf(user);
        neutrinos = neutrinoToken.balanceOf(user);
        gammas = gammaToken.balanceOf(user);
    }
    
    /**
     * @dev Get nuclear reaction statistics
     */
    function getReactionStats() external view returns (
        uint256 ppFusions,
        uint256 pdFusions,
        uint256 he3Fusions,
        uint256 completePPChains,
        uint256 alphaDecays,
        uint256 totalEnergy,
        uint256 totalProtons,
        uint256 totalHelium4
    ) {
        ppFusions = ppFusionCount;
        pdFusions = pdFusionCount;
        he3Fusions = he3FusionCount;
        completePPChains = completePPChainCount;
        alphaDecays = alphaDecayCount;
        totalEnergy = totalEnergyReleased;
        totalProtons = protonToken.totalSupply();
        totalHelium4 = helium4Token.totalSupply();
    }
    
    /**
     * @dev Get all particle token addresses
     */
    function getTokenAddresses() external view returns (
        address protonAddr,
        address deuteriumAddr,
        address helium3Addr,
        address helium4Addr,
        address positronAddr,
        address neutrinoAddr,
        address gammaAddr
    ) {
        protonAddr = address(protonToken);
        deuteriumAddr = address(deuteriumToken);
        helium3Addr = address(helium3Token);
        helium4Addr = address(helium4Token);
        positronAddr = address(positronToken);
        neutrinoAddr = address(neutrinoToken);
        gammaAddr = address(gammaToken);
    }
    
    /**
     * @dev Calculate nuclear efficiency
     * Returns the percentage of initial protons converted to helium
     */
    function getNuclearEfficiency() external view returns (uint256 efficiencyPercent) {
        uint256 initialProtons = 10000; // Starting amount
        uint256 currentProtons = protonToken.totalSupply();
        uint256 protonsConsumed = initialProtons - currentProtons;
        
        if (protonsConsumed > 0) {
            efficiencyPercent = (protonsConsumed * 100) / initialProtons;
        } else {
            efficiencyPercent = 0;
        }
    }
}

// DEPLOYMENT AND TESTING INSTRUCTIONS:
//
// 1. DEPLOY:
//    - Open Remix IDE (remix.ethereum.org)
//    - Create new file: HeliumFormationSystem.sol
//    - Copy this entire code
//    - Compile with Solidity 0.8.19
//    - Deploy HeliumFormationSystem contract
//
// 2. INITIAL STATE:
//    - Deployer gets 10,000 protons (H)
//    - All other particles start at 0
//    - Call getUserBalances(YOUR_ADDRESS) to verify
//
// 3. TEST INDIVIDUAL NUCLEAR REACTIONS:
//    - ppFusion(): p + p -> D + e+ + ve (need 2 protons)
//    - pdFusion(): D + p -> He-3 + y (need 1 deuterium + 1 proton)
//    - he3Fusion(): He-3 + He-3 -> He-4 + 2p (need 2 He-3 nuclei)
//    - alphaDecay(): He-4 -> 2D (need 1 He-4, reverse process)
//
// 4. TEST COMPLETE REACTION:
//    - completePPChain(): 4H -> He-4 + 2e+ + 2ve (need 4 protons)
//
// 5. EXAMPLE STELLAR WORKFLOW:
//    - Start: 10,000 H, 0 others
//    - ppFusion() × 5: 9,990 H, 5 D, 5 e+, 5 νe
//    - pdFusion() × 5: 9,985 H, 0 D, 5 He-3, 5 y, 5 e+, 5 ve
//    - he3Fusion() × 2: 9,989 H, 0 D, 1 He-3, 2 He-4, 5 y, 5 e+, 5 ve
//    - completePPChain() × 100: 9,589 H, 0 D, 1 He-3, 102 He-4, 205 e+, 205 ve
//
// 6. CONSERVATION LAWS:
//    - Baryon number conserved (total nucleons constant)
//    - Charge conserved (protons = positrons + net positive charge)
//    - Energy increases with each fusion (tracked in totalEnergyReleased)
//    - Lepton number conserved (neutrinos balance positrons in weak interactions)
//
// 7. PHYSICS NOTES:
//    - PP-chain is how stars like our Sun produce energy
//    - Takes ~10 billion years for a proton to complete the chain in the Sun
//    - Each complete cycle converts 0.7% of mass to energy (E=mc^2)
//    - Temperature must be >10 million K for fusion to occur
//    - This contract simulates stellar nucleosynthesis processes
