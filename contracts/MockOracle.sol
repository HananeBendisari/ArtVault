// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IOracle.sol";
import "forge-std/console.sol";



contract MockOracle is IOracle {
    address public owner;
    uint256 public price;


    constructor(uint256 _price) {
    price = _price;
    owner = msg.sender;
}


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setPrice(uint256 _price) external onlyOwner {
    price = _price;
}


    function getLatestPrice() external view override returns (uint256) {
    console.log("Returning price:", price);
    return uint256(price);
}

}
