// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseContract.sol";

/**
 * @title ValidationContract
 * @dev Handles project validation by assigned validators.
 */
contract ValidationContract is BaseContract {
    
    /**
     * @dev Assigns a validator to a project.
     * @param _projectId The ID of the project.
     * @param _validator The address of the validator.
     */
    function addValidator(uint256 _projectId, address _validator) public projectExists(_projectId) onlyClient(_projectId) {
        Project storage project = projects[_projectId];

        require(_validator != address(0), "Invalid validator address.");
        require(!project.released, "Funds already released.");
        require(!project.validated, "Cannot change validator after validation.");

        project.validator = _validator;

        emit ValidatorAssigned(_projectId, _validator);
    }

    /**
     * @dev Validates the project, allowing milestone releases.
     * @param _projectId The ID of the project.
     */
    function validateProject(uint256 _projectId) public projectExists(_projectId) onlyValidator(_projectId) {
        require(!projects[_projectId].validated, "Project already validated.");
        Project storage project = projects[_projectId];
        require(!project.released, "Funds already released.");
        require(project.validator != address(0), "No validator assigned.");

        project.validated = true;

        emit ProjectValidated(_projectId, msg.sender);
    }
}
