// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KPACOTA is ERC20, Ownable {
    uint8 private constant DECIMALS = 0;
    uint256 private constant MAX_SUPPLY = 1;

    address public immutable osumPosum;
    uint256 public lastSignalTime;
    uint256 public constant COOLDOWN = 60 seconds;

    uint256 public constant EPOCH = 432921600; // September 16, 1983

    event Signal(string data);

    constructor(address _osumPosum)
        ERC20("KPACOTA", "EYE")
        Ownable(msg.sender)
    {
        require(_osumPosum != address(0), "osumPosum address cannot be zero");
        osumPosum = _osumPosum;
    }

    /// @notice Emits a signal as "Vostorhennaya fignya", <seconds since 09-16-1983>, <3", mints and burns a token.
    function mintAndSignal() external {
        require(msg.sender == osumPosum, "unOsumPosum, go away!");
        require(block.timestamp >= lastSignalTime + COOLDOWN, "IT IS KPACOTA MILES O'CLOCK PAST REALITY! Please wait ajar, be so beavers <3");

        lastSignalTime = block.timestamp;

        uint256 posumEpoch = block.timestamp - EPOCH;
        string memory signal = string(
            abi.encodePacked("BEHOLD, THE KPACOTA TO EYE DELIVERY CERTIFICATE #", _uintToString(posumEpoch), ", <3")
        );

        _mint(address(this), 1);
        emit Signal(signal);
        _burn(address(this), 1);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @dev Internal helper to convert uint256 to string
    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
