// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";
import "./DisputeModule.sol";
import "./IOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ArtVault
 * @dev Main contract that composes escrow and validation functionalities.
 */
contract ArtVault is Ownable, BaseContract, EscrowContract, ValidationContract, DisputeModule {
    IOracle internal _oracleOverride; // Used for test overrides
    IOracle public oracle;            // Used in production

    constructor() Ownable(msg.sender) {}

    function createProject(
        uint256 _projectId,
        address payable _artist,
        uint256 _milestoneCount
    ) public {
        require(projects[_projectId].client == address(0), "Project already exists");

        projects[_projectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: 0,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0
        });

        projectCount++;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }

    function setOracleOverride(IOracle o) external virtual {
        _oracleOverride = o;
    }

    function getOracle() public view virtual override returns (IOracle) {
        if (address(_oracleOverride) != address(0)) {
            return _oracleOverride;
        }
        return oracle;
    }
}
