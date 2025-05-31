// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Inherited base modules
import "./BaseContract.sol";
import "./EscrowContract.sol";
import "./ValidationContract.sol";
import "./modules/DisputeModule.sol";
import "./interfaces/IOracle.sol";
import "./Pausable.sol";

// Access control
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces for optional rule modules
import {IForteRules} from "./interfaces/IForteRules.sol";
import {IFallbackModule} from "./interfaces/IFallbackModule.sol";
import {ISignatureModule} from "./interfaces/ISignatureModule.sol";

/**
 * @title ArtVault
 * @dev Escrow contract for milestone-based payments, with modular rule engine integration.
 * Core business logic is inherited; optional enforcement logic is injected via external modules.
 */
contract ArtVault is Pausable, Ownable, BaseContract, EscrowContract, ValidationContract, DisputeModule {
    
    // External modules injected at runtime (can be mocks or real rules)
    IForteRules public forteRules;
    IFallbackModule public fallbackModule;
    ISignatureModule public signatureModule;

    // Oracle management
    IOracle internal _oracleOverride; // Used for test overrides
    IOracle public oracle;            // Used in production

    // Project-level configuration: enables or disables rule enforcement per project
    struct ProjectConfig {
        bool useForteRules;
        bool useFallback;
        bool useSignature;
    }

    // Mapping of projectId => ProjectConfig
    mapping(uint256 => ProjectConfig) public projectConfigs;

    constructor() Pausable(msg.sender) Ownable(msg.sender) {}

    /**
     * @dev Creates a new project with artist and number of milestones.
     * Callable by the client only (enforced externally).
     */
    function createProject(
        uint256 _projectId,
        address payable _artist,
        uint256 _milestoneCount
    ) external whenNotPaused {
        require(projects[_projectId].client == address(0), "Project already exists");

        projects[_projectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: 0,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false,
            createdAt: block.timestamp
        });

        projectCount++;
    }

    /**
     * @dev Sets the rule configuration for a project.
     * Only the original client is allowed to change this configuration.
     */
    function setProjectConfig(
        uint256 _projectId,
        bool _useForte,
        bool _useFallback,
        bool _useSig
    ) external whenNotPaused {
        require(msg.sender == projects[_projectId].client, "Only client can configure project");

        projectConfigs[_projectId] = ProjectConfig({
            useForteRules: _useForte,
            useFallback: _useFallback,
            useSignature: _useSig
        });
    }

    /**
     * @dev Injects the ForteRules module contract.
     */
    function setForteRulesModule(address _addr) external onlyOwner whenNotPaused {
        forteRules = IForteRules(_addr);
    }

    /**
     * @dev Injects the Fallback module contract.
     */
    function setFallbackModule(address _addr) external onlyOwner whenNotPaused {
        fallbackModule = IFallbackModule(_addr);
    }

    /**
     * @dev Injects the Signature module contract.
     */
    function setSignatureModule(address _addr) external onlyOwner whenNotPaused {
        signatureModule = ISignatureModule(_addr);
    }

    /**
     * @dev Sets the production oracle.
     */
    function setOracle(address _oracle) external onlyOwner whenNotPaused {
        oracle = IOracle(_oracle);
    }

    /**
     * @dev Overrides the oracle (used for testing).
     */
    function setOracleOverride(IOracle o) public virtual {
        _oracleOverride = o;
    }

    /**
     * @dev Returns the active oracle (test override takes priority).
     */
    function getOracle() public view virtual override returns (IOracle) {
        if (address(_oracleOverride) != address(0)) {
            return _oracleOverride;
        }
        return oracle;
    }

    /**
     * @dev Releases the next milestone for a project.
     * Incorporates external rules (if enabled) before allowing release.
     */
    function releaseMilestone(uint256 projectId) public virtual override whenNotPaused onlyClient(projectId) {
        // Load rule configuration for the project
        ProjectConfig memory config = projectConfigs[projectId];

        uint256 milestoneId = projects[projectId].milestonesPaid;

        // ForteRules check (e.g. oracleDelivered == true, isFraud == false, etc.)
        if (config.useForteRules) {
            require(
                address(forteRules) != address(0),
                "ForteRules module not set"
            );
            require(
                forteRules.canRelease(projectId, milestoneId),
                "Release blocked by Forte rules"
            );
        }

        // Fallback release logic (e.g. delay exceeded)
        if (config.useFallback) {
            require(
                address(fallbackModule) != address(0),
                "Fallback module not set"
            );
            require(
                fallbackModule.isFallbackReady(projectId, milestoneId),
                "Fallback condition not met"
            );
        }

        // Double-signature confirmation logic
        if (config.useSignature) {
            require(
                address(signatureModule) != address(0),
                "Signature module not set"
            );
            require(
                signatureModule.canReleaseBySignature(projectId),
                "Both client and artist must confirm"
            );
        }

        // Core release logic (unchanged from EscrowContract)
        _executeRelease(projectId);
    }

    function depositFunds(address _artist, uint256 _milestoneCount) external payable override whenNotPaused {
        require(_artist != address(0), "Invalid artist address");
        require(msg.value > 0, "Amount must be > 0");
        require(_milestoneCount > 0, "Milestone count must be greater than zero");

        uint256 newProjectId = projectCount;

        projects[newProjectId] = Project({
            client: msg.sender,
            artist: _artist,
            amount: msg.value,
            released: false,
            validator: address(0),
            validated: false,
            milestoneCount: _milestoneCount,
            milestonesPaid: 0,
            useFallback: false,
            fallbackDelay: 0,
            useSignature: false,
            createdAt: block.timestamp
        });

        projectCount++;

        emit FundsDeposited(newProjectId, msg.sender, _artist, msg.value);
    }
}
