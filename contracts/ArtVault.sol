// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Inherited base modules
import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";
import "./DisputeModule.sol";
import "./IOracle.sol";

// Access control
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces for optional rule modules
import {IForteRules} from "./interfaces/IForteRules.sol";
import {IFallbackModule} from "./interfaces/IFallbackModule.sol";
import {ISignatureModule} from "./interfaces/ISignatureModule.sol";

/**
 * @title ArtVault
 * @dev Main contract that composes escrow and validation functionalities.
 * Supports optional modular rule engines (Forte, Fallback, Signature).
 */
contract ArtVault is Ownable, BaseContract, EscrowContract, ValidationContract, DisputeModule {
    
    // Optional rule modules (settable externally)
    IForteRules public forteRules;
    IFallbackModule public fallbackModule;
    ISignatureModule public signatureModule;

    // Oracle management
    IOracle internal _oracleOverride; // Used for test overrides
    IOracle public oracle;            // Used in production

    // Per-project configuration for rule modules
    struct ProjectConfig {
        bool useForteRules;
        bool useFallback;
        bool useSignature;
    }

    mapping(uint256 => ProjectConfig) public projectConfigs;

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Create a new project with a given artist and number of milestones.
     * Callable by the client only.
     */
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

    /**
     * @dev Set rule usage config for a project (ForteRules, Fallback, Signature).
     * Callable only by the client who owns the project.
     */
    function setProjectConfig(
        uint256 _projectId,
        bool _useForte,
        bool _useFallback,
        bool _useSig
    ) external {
        require(msg.sender == projects[_projectId].client, "Only client can configure project");

        projectConfigs[_projectId] = ProjectConfig({
            useForteRules: _useForte,
            useFallback: _useFallback,
            useSignature: _useSig
        });
    }

    /**
     * @dev Set production oracle.
     */
    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }

    /**
     * @dev Set oracle override for testing.
     */
    function setOracleOverride(IOracle o) external virtual {
        _oracleOverride = o;
    }

    /**
     * @dev Return the active oracle (test or prod).
     */
    function getOracle() public view virtual override returns (IOracle) {
        if (address(_oracleOverride) != address(0)) {
            return _oracleOverride;
        }
        return oracle;
    }

    /**
     * @dev Inject ForteRules module.
     */
    function setForteRulesModule(address _addr) external {
        forteRules = IForteRules(_addr);
    }

    /**
     * @dev Inject Fallback module.
     */
    function setFallbackModule(address _addr) external {
        fallbackModule = IFallbackModule(_addr);
    }

    /**
     * @dev Inject Signature module.
     */
    function setSignatureModule(address _addr) external {
        signatureModule = ISignatureModule(_addr);
    }
}
