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

// Optional rule modules
import {IForteRules} from "./interfaces/IForteRules.sol";
import {IFallbackModule} from "./interfaces/IFallbackModule.sol";
import {ISignatureModule} from "./interfaces/ISignatureModule.sol";

// ForteRulesModule interface
interface IRulesModule {
    function validateRelease(address user, uint256 rulesetId, bytes calldata data) external view returns (bool);
}

// Gelato meta-tx: Import GelatoRelayContextERC2771 for callWithSyncFeeERC2771
import {GelatoRelayContextERC2771} from "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";

/**
 * @title ArtVault
 * @dev Escrow contract for milestone-based payments, with modular rule engine integration.
 */
contract ArtVault is Pausable, BaseContract, EscrowContract, ValidationContract, DisputeModule, GelatoRelayContextERC2771 {
    // External modules
    IForteRules public forteRules;
    IFallbackModule public fallbackModule;
    ISignatureModule public signatureModule;

    // Rules engine module (ForteRulesModule) and per-project config
    address public rulesModule;
    mapping(uint256 => uint256) public rulesetIds;

    // Oracle
    IOracle internal _oracleOverride;
    IOracle public oracle;

    struct ProjectConfig {
        bool useForteRules;
        bool useFallback;
        bool useSignature;
    }

    mapping(uint256 => ProjectConfig) public projectConfigs;

    // Gelato meta-tx: No trustedForwarder needed, use GelatoRelayContextERC2771
    constructor() Pausable() {}

    function createProject(
        uint256 _projectId,
        address payable _artist,
        uint256 _milestoneCount
    ) external virtual whenNotPaused {
        require(projects[_projectId].client == address(0), "Project already exists");
        require(_artist != address(0), "Invalid artist address");
        require(_milestoneCount > 0, "Milestone count must be greater than 0");

        projects[_projectId] = Project({
            client: _msgSender(), // Meta-tx: Override msg.sender
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

    function setProjectConfig(
        uint256 _projectId,
        bool _useForte,
        bool _useFallback,
        bool _useSig
    ) external whenNotPaused {
        require(_msgSender() == projects[_projectId].client, "Only client can configure project"); // Meta-tx: Override msg.sender
        require(projects[_projectId].client != address(0), "Project does not exist");

        projectConfigs[_projectId] = ProjectConfig({
            useForteRules: _useForte,
            useFallback: _useFallback,
            useSignature: _useSig
        });
    }

    function setForteRulesModule(address _addr) external onlyOwner whenNotPaused {
        forteRules = IForteRules(_addr);
    }

    function setFallbackModule(address _addr) external onlyOwner whenNotPaused {
        fallbackModule = IFallbackModule(_addr);
    }

    function setSignatureModule(address _addr) external onlyOwner whenNotPaused {
        signatureModule = ISignatureModule(_addr);
    }

    function setRulesModule(address _addr) external onlyOwner whenNotPaused {
        rulesModule = _addr;
    }

    function setRulesetId(uint256 projectId, uint256 rulesetId) external onlyOwner {
        require(projects[projectId].client != address(0), "Project does not exist");
        rulesetIds[projectId] = rulesetId;
    }

    function setOracle(address _oracle) external onlyOwner whenNotPaused {
        oracle = IOracle(_oracle);
    }

    function setOracleOverride(IOracle o) public virtual {
        _oracleOverride = o;
    }

    function getOracle() public view virtual override returns (IOracle) {
        return address(_oracleOverride) != address(0) ? _oracleOverride : oracle;
    }

    function releaseMilestone(uint256 projectId) public virtual override onlyGelatoRelayERC2771 whenNotPaused onlyClient(projectId) {
        // Gelato meta-tx: Transfer relay fee
        _transferRelayFee();
        ProjectConfig memory config = projectConfigs[projectId];
        uint256 milestoneId = projects[projectId].milestonesPaid;

        // ForteRules (legacy interface)
        if (config.useForteRules && address(forteRules) != address(0)) {
            require(forteRules.canRelease(projectId, milestoneId), "Blocked by Forte rules");
        }

        // ForteRulesModule with dynamic ruleset
        if (rulesetIds[projectId] > 0 && address(rulesModule) != address(0)) {
            bytes memory data = abi.encode(projectId, milestoneId);
            bool allowed = IRulesModule(rulesModule).validateRelease(_getMsgSender(), rulesetIds[projectId], data); // Gelato meta-tx: Use _getMsgSender
            require(allowed, "Release blocked by Forte rules");
        }

        if (config.useFallback) {
            require(address(fallbackModule) != address(0), "Fallback module not set");
            require(fallbackModule.isFallbackReady(projectId), "Fallback not ready");
        }

        if (config.useSignature) {
            require(address(signatureModule) != address(0), "Signature module not set");
            require(signatureModule.canReleaseBySignature(projectId), "Signature required");
        }

        _executeRelease(projectId);
    }

    function depositFunds(address _artist, uint256 _milestoneCount) external payable override whenNotPaused {
        require(_artist != address(0), "Invalid artist address");
        require(msg.value > 0, "Zero value");
        require(_milestoneCount > 0, "Milestone count must be greater than 0");

        uint256 newProjectId = projectCount;

        projects[newProjectId] = Project({
            client: _msgSender(), // Meta-tx: Override msg.sender
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
        emit FundsDeposited(newProjectId, _msgSender(), _artist, msg.value); // Meta-tx: Override msg.sender
    }

    // Override _getMsgSender to use GelatoRelayContextERC2771 logic
    function _getMsgSender() internal view override(BaseContract, GelatoRelayContextERC2771) returns (address) {
        return GelatoRelayContextERC2771._getMsgSender();
    }
}
