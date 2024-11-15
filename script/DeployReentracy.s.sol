// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/reentracy.sol";
import "../src/reentrancyExploit.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy AssetVault contract
        AssetVault assetVault = new AssetVault();

        // Deploy ReentrancyExploit contract with the address of AssetVault
        reentrancyExploit exploit = new reentrancyExploit(address(assetVault));

        // Execute the attack
        exploit.attack{value: 1 ether}();

        vm.stopBroadcast();
    }
}
