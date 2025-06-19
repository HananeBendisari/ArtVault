// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IOracle.sol";

interface IForteCompliance {
    function getAccessLevel(address user) external view returns (uint256);
}

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
        uint256 createdAt;
    }

    mapping(uint256 => Project) public projects;
    uint256 public projectCount;

    IForteCompliance public forteCompliance;
    uint256 public constant REQUIRED_KYC_LEVEL = 3;

    event FundsDeposited(uint256 projectId, address indexed client, address indexed artist, uint256 amount);
    event FundsReleased(uint256 projectId, address indexed artist, uint256 amount);
    event FundsRefunded(uint256 projectId, address indexed client);
    event ProjectValidated(uint256 projectId, address indexed validator);
    event ValidatorAssigned(uint256 projectId, address indexed validator);
    event ClientRefunded(uint256 projectId, address indexed client, uint256 amount);
    event MilestoneReleased(uint256 projectId, uint256 milestoneIndex, uint256 amount);

    error ProjectDoesNotExist();
    error OnlyClient();
    error OnlyAssignedValidator();
    error KYCNotApproved();

    /**
     * @dev Modifier to ensure the project exists.
     * @param _projectId The ID of the project.
     */
    modifier projectExists(uint256 _projectId) {
        if (projects[_projectId].client == address(0)) revert ProjectDoesNotExist();
        _;
    }

    /**
     * @dev Modifier to restrict access to the project client.
     * @param _projectId The ID of the project.
     */
    modifier onlyClient(uint256 _projectId) {
        if (msg.sender != projects[_projectId].client) revert OnlyClient();
        _;
    }

    /**
     * @dev Modifier to restrict access to the assigned validator.
     * @param _projectId The ID of the project.
     */
    modifier onlyValidator(uint256 _projectId) {
        if (msg.sender != projects[_projectId].validator) revert OnlyAssignedValidator();
        _;
    }

    /**
     * @dev Modifier to restrict access to KYC-verified users.
     */
    modifier onlyKYCApproved() {
        if (!isKYCApproved(msg.sender)) revert KYCNotApproved();
        _;
    }

    /**
     * @dev Returns true if the user's KYC level is sufficient.
     */
    function isKYCApproved(address user) public view returns (bool) {
        return forteCompliance.getAccessLevel(user) >= REQUIRED_KYC_LEVEL;
    }

    /**
     * @dev Sets the Forte compliance contract address.
     */
    function setForteCompliance(address _compliance) external {
        forteCompliance = IForteCompliance(_compliance);
    }

    /**
    * @dev Returns all details of a project.
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
            bool useSignature,
            uint256 createdAt
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
            p.useSignature,
            p.createdAt
        );
    }
    
    function getOracle() public view virtual returns (IOracle) {
        return IOracle(address(0));
    }
}
