// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IOracle.sol";


/**
 * @title BaseContract
 * @dev Stores the project structure, events, and basic modifiers.
 */
contract BaseContract {
    struct Project {
        address client;
        address artist;
        uint256 amount;
        bool released;
        address validator;
        bool validated;
        uint256 milestoneCount;
        uint256 milestonesPaid;
        bool useFallback;
        uint256 fallbackDelay;
        bool useSignature;
    }

    mapping(uint256 => Project) public projects;
    uint256 public projectCount;

    event FundsDeposited(uint256 projectId, address indexed client, address indexed artist, uint256 amount);
    event FundsReleased(uint256 projectId, address indexed artist, uint256 amount);
    event FundsRefunded(uint256 projectId, address indexed client);
    event ProjectValidated(uint256 projectId, address indexed validator);
    event ValidatorAssigned(uint256 projectId, address indexed validator);
    event ClientRefunded(uint256 projectId, address indexed client, uint256 amount);
    event MilestoneReleased(uint256 projectId, uint256 milestoneIndex, uint256 amount);

    /**
     * @dev Modifier to ensure the project exists.
     * @param _projectId The ID of the project.
     */
    modifier projectExists(uint256 _projectId) {
        require(projects[_projectId].client != address(0), "Error: Project does not exist.");
        _;
    }

    /**
     * @dev Modifier to restrict access to the project client.
     * @param _projectId The ID of the project.
     */
    modifier onlyClient(uint256 _projectId) {
        require(msg.sender == projects[_projectId].client, "Error: Only the client can perform this action.");
        _;
    }

    /**
     * @dev Modifier to restrict access to the assigned validator.
     * @param _projectId The ID of the project.
     */
    modifier onlyValidator(uint256 _projectId) {
        require(msg.sender == projects[_projectId].validator, "Error: Only the assigned validator can perform this action.");
        _;
    }

    /**
    * @dev Returns all details of a project.
    * @param _projectId The ID of the project.
    */
    function getProject(uint256 _projectId)
        public
        view
        returns (
            address client,
            address artist,
            uint256 amount,
            bool released,
            address validator,
            bool validated,
            uint256 milestoneCount,
            uint256 milestonesPaid,
            bool useFallback,
            uint256 fallbackDelay,
            bool useSignature
        )
    {
        Project memory p = projects[_projectId];
        return (
            p.client,
            p.artist,
            p.amount,
            p.released,
            p.validator,
            p.validated,
            p.milestoneCount,
            p.milestonesPaid,
            p.useFallback,
            p.fallbackDelay,
            p.useSignature
        );
    }
    
    function getOracle() public view virtual returns (IOracle) {
        return IOracle(address(0));
    }


    

}
