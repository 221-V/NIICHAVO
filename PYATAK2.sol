// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GOST71862 is ERC20, Ownable {
    address public immutable Janus_Ektovich_Nevstruev;
    address public immutable PrivalovUINT;
    mapping(address => uint256) public lastCooldownStart;

    event BurnSignal(address indexed from, string data);
    event JanusSelfTransfer(address indexed janus, uint256 amount, string message);

    modifier onlyJanus() {
        require(msg.sender == Janus_Ektovich_Nevstruev, "NOT JANUS");
        _;
    }

    modifier onlyHolder() {
        require(balanceOf(msg.sender) > 0, "HET TOKEHOB");
        _;
    }

    constructor(address _janus)
        ERC20("GOST-718-62", "NIICHAVO_PYATAK")
        Ownable(msg.sender)
    {
        require(_janus != address(0), "0 IS NOT THE ADDRESS OF JANUS");
        Janus_Ektovich_Nevstruev = _janus;
        PrivalovUINT = msg.sender;

        _mint(Janus_Ektovich_Nevstruev, 1);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function burnAndSignal(string memory data) external onlyHolder {
        _enforceCooldown();

        _burn(msg.sender, 1);
        emit BurnSignal(msg.sender, data);

        _mint(msg.sender, 1);
        lastCooldownStart[msg.sender] = block.timestamp;
    }

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

    function mint(address to, uint256 amount) external onlyJanus {
        require(to == Janus_Ektovich_Nevstruev, "PLEASE ASK JANUS FOR PYATAK");
        require(totalSupply() + amount <= 1, "THERE ALREADY IS A PYATAK");
        _mint(to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Allow Janus to transfer to himself with special messages
        if (
            from == Janus_Ektovich_Nevstruev &&
            to == Janus_Ektovich_Nevstruev &&
            (amount == 0 || amount == 1)
        ) {
            super._update(from, to, amount);

            if (amount == 0) {
                emit JanusSelfTransfer(from, amount, "TIME OF DAY IS BLUEBERRY");
            } else {
                emit JanusSelfTransfer(from, amount, "IT IS ZHVANETSKIY O'CLOCK IN PEPPERLAND");
            }

            return;
        }

        if (from != address(0) && to != address(0)) {
            require(
                from == Janus_Ektovich_Nevstruev || to == Janus_Ektovich_Nevstruev,
                "Time of day is BANANAS :)"
            );
        }

        super._update(from, to, amount);
    }
}
