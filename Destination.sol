// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }


    function createToken(address underlying, string memory name, string memory symbol, address admin) public onlyRole(CREATOR_ROLE) returns (address) {
        require(underlying_tokens[underlying] == address(0), "Token already created for this asset");

        BridgeToken newToken = new BridgeToken(underlying, name, symbol, admin);
        address newTokenAddress = address(newToken);

        underlying_tokens[underlying] = newTokenAddress;
        wrapped_tokens[newTokenAddress] = underlying;

        emit Creation(newTokenAddress, underlying);  // Assuming Creation event requires 2 arguments

        return newTokenAddress;
    }

    function wrap(address underlying, address recipient, uint256 amount) public onlyRole(WARDEN_ROLE) {
        address bridgeTokenAddress = underlying_tokens[underlying];
        require(bridgeTokenAddress != address(0), "No wrapped token for this asset");

        BridgeToken(bridgeTokenAddress).mint(recipient, amount);

        emit Wrap(bridgeTokenAddress, underlying, recipient, amount);  // Assuming Wrap event requires 4 arguments
    }

    function unwrap(address bridgeToken, address recipient, uint256 amount) public {
        require(wrapped_tokens[bridgeToken] != address(0), "Invalid BridgeToken");

        BridgeToken(bridgeToken).burnFrom(msg.sender, amount);

        emit Unwrap(bridgeToken, recipient, amount, msg.sender);  // Assuming Unwrap event requires 4 arguments without block.timestamp
    }



}


