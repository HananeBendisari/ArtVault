// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/BaseContract.sol";
import "../../contracts/EscrowContract.sol";
import "../../contracts/ValidationContract.sol";
import "../../contracts/modules/DisputeModule.sol";
import "../../contracts/modules/FallbackModule.sol";
import "../../contracts/modules/SignatureModule.sol";
import "../../contracts/interfaces/IOracle.sol";

/**
 * @title TestVaultFull
 * @dev Test contract that combines all modules for integration testing
 */
contract TestVaultFull is 
    BaseContract,
    EscrowContract,
    ValidationContract,
    DisputeModule,
    FallbackModule,
    SignatureModule
{
    // Oracle for tests
    IOracle private oracle;

    // Current timestamp for tests
    uint256 private currentTime;

    // Mapping for signatures
    mapping(uint256 => mapping(address => bool)) public signatures;

    // Mapping for total deposits
    mapping(uint256 => uint256) public totalDeposits;

    constructor() {
        currentTime = block.timestamp;
    }

    /**
     * @dev Creates a new project with all necessary parameters
     * @param projectId Project ID
     * @param artist Artist address
     * @param milestoneCount Number of milestones
     * @param amount Total project amount
     */
    function createProject(
        uint256 projectId,
        address payable artist,
        uint256 milestoneCount,
        uint256 amount
    ) external payable {
        require(msg.value == amount, "Amount mismatch");
        
        // Base project creation
        projects[projectId] = Project({
            client: msg.sender,
            artist: artist,
            amount: amount,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: milestoneCount,
            milestonesPaid: 0,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false,
            createdAt: block.timestamp
        });
        
        // Module initialization
        if (projects[projectId].useSignature) {
            signatures[projectId][msg.sender] = false;
            signatures[projectId][artist] = false;
        }

        // Fund registration
        totalDeposits[projectId] = amount;
    }

    /**
     * @dev Configures all modules for a project
     * @param projectId Project ID
     * @param useFallback Enable fallback module
     * @param useSignature Enable signature module
     * @param fallbackDelay Delay for fallback (in seconds)
     */
    function setFullConfig(
        uint256 projectId,
        bool useFallback,
        bool useSignature,
        uint256 fallbackDelay
    ) external {
        Project storage project = projects[projectId];
        require(msg.sender == project.client, "Only client can set config");

        project.useFallback = useFallback;
        project.useSignature = useSignature;
        project.fallbackDelay = fallbackDelay;
    }

    /**
     * @dev Sets the oracle for tests
     * @param _oracle Oracle address
     */
    function setOracle(IOracle _oracle) external {
        oracle = _oracle;
    }

    /**
     * @dev Sets the current timestamp for tests
     * @param timestamp New timestamp
     */
    function setCurrentTime(uint256 timestamp) external {
        currentTime = timestamp;
    }

    /**
     * @dev Override of block.timestamp function for tests
     */
    function _getCurrentTime() internal view returns (uint256) {
        return currentTime;
    }

    /**
     * @dev Override of _getOracle function for tests
     */
    function getOracle() public view override returns (IOracle) {
        return oracle;
    }
} 