// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error FundsAlreadyReleased();
error CannotChangeValidatorAfterValidation();
error InvalidValidatorAddress();
error ProjectAlreadyValidated();
error ValidatorNotAssigned();

import "./BaseContract.sol";

/**
 * @title ValidationContract
 * @dev Handles validator assignment and project validation.
 */
contract ValidationContract is BaseContract {

    /**
     * @dev Assigns a validator to a project.
     * Can only be called by the project client.
     * @param _projectId The ID of the project.
     * @param _validator The address of the validator.
     */
    function addValidator(uint256 _projectId, address _validator)
        public
        projectExists(_projectId)
        onlyClient(_projectId)
    {
        Project storage project = projects[_projectId];

        if (project.released) revert FundsAlreadyReleased();
        if (project.validated) revert CannotChangeValidatorAfterValidation();
        if (_validator == address(0)) revert InvalidValidatorAddress();

        project.validator = _validator;

        emit ValidatorAssigned(_projectId, _validator);
    }

    /**
     * @dev Marks the project as validated.
     * Can only be called by the assigned validator.
     * @param _projectId The ID of the project.
     */
    function validateProject(uint256 _projectId)
        public
        projectExists(_projectId)
        onlyValidator(_projectId)
    {
        Project storage project = projects[_projectId];

        if (project.validated) revert ProjectAlreadyValidated();
        if (project.released) revert FundsAlreadyReleased();
        if (project.validator == address(0)) revert ValidatorNotAssigned();

        project.validated = true;

        emit ProjectValidated(_projectId, msg.sender);
    }
}
