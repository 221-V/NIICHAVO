// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OCCAMS_RAZOR is ERC20Burnable, Ownable {
    address public immutable OCCAM;
    mapping(address => uint256) public lastCooldownStart;

    event TimeOfDayIsEverywhere(string message, uint256 timestamp);
    event PaperCutDangerZone(string message, uint256 timestamp);
    event Minteger(string message, uint256 timestamp);
    event Burnsicle(string message, uint256 timestamp);

    constructor() ERC20("OCCAMS-RAZOR", "OCRZ") Ownable(msg.sender) {
        OCCAM = msg.sender;
        _mint(OCCAM, 0); // Initial and final mint: exactly 0 tokens
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        require(amount == 0, "Only zero-amount transfers allowed");
    }

    /// Cooldown logic
    function _enforceCooldown() internal view {
        uint256 lastTime = lastCooldownStart[msg.sender];
        if (lastTime == 0) return;

        uint256 hour = (lastTime / 60 / 60) % 24;
        uint256 elapsed = block.timestamp - lastTime;

        if (hour < 12) {
            require(elapsed >= 60, "PODOZHDITE MINUTOCHKU, BVKSH <3 :))");
        } else {
            require(elapsed >= 3600, "PODOZHDITE SEICHASIK, BVKSH <3 :))");
        }
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (amount == 0 && msg.sender == to) {
            _enforceCooldown();
            emit TimeOfDayIsEverywhere("TIME OF DAY IS EVERYWHERE", block.timestamp);
            lastCooldownStart[msg.sender] = block.timestamp;
            return true;
        }
        return super.transfer(to, amount);
    }

    function burnZeroAndReMint() external {
        _enforceCooldown();
        emit PaperCutDangerZone("PAPER CUT!!! DANGER ZONE!!!", block.timestamp);
        _burn(msg.sender, 0);
        _mint(msg.sender, 0);
        lastCooldownStart[msg.sender] = block.timestamp;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == OCCAM, "ALL THE MINTEGER ARE BELONG TO OCCAM");
        _enforceCooldown();
        require(amount == 0, "ONLY ZERO MINTEGERS CAN BE MINTED");
        emit Minteger("EVERY ZERO IS A MINTEGER", block.timestamp);
        _mint(to, amount);
        lastCooldownStart[msg.sender] = block.timestamp;
    }

    function burnFrom(address account, uint256 amount) public override {
        require(msg.sender == OCCAM, "OCCAM DENIES THE RAZOR");
        _enforceCooldown();
        emit Burnsicle("ZERO IS ON DUTYEVICH TODAY, THANK YOU <3", block.timestamp);
        _burn(account, amount);
        lastCooldownStart[msg.sender] = block.timestamp;
    }
}
