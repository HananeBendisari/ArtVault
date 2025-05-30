// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/IOracle.sol";

/**
 * @title MockOracle
 * @dev Mock implementation of IOracle for testing purposes
 */
contract MockOracle is IOracle {
    uint256 public price;
    address public immutable owner;
    bool public shouldRevert;
    string public customError;

    error Unauthorized(address caller, address owner);
    error CustomOracleError(string message);
    
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event RevertStateUpdated(bool shouldRevert, string customError);

    constructor(uint256 _price) {
        price = _price;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender, owner);
        }
        _;
    }

    function setPrice(uint256 _price) external onlyOwner {
        uint256 oldPrice = price;
        price = _price;
        emit PriceUpdated(oldPrice, _price);
    }

    function setRevertState(bool _shouldRevert, string calldata _customError) external onlyOwner {
        shouldRevert = _shouldRevert;
        customError = _customError;
        emit RevertStateUpdated(_shouldRevert, _customError);
    }

    function getLatestPrice() external view override returns (uint256) {
        if (shouldRevert) {
            revert CustomOracleError(customError);
        }
        return price;
    }
}
