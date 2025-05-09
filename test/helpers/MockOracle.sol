// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/IOracle.sol";

contract MockOracle is IOracle {
    uint256 public price;
    address public owner;

    constructor(uint256 _price) {
        price = _price;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getLatestPrice() external view override returns (uint256) {
        return price;
    }
}
