// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/reentrancyExploit.sol";

contract CheckBalanceScript is Script {
    function run() external {
        vm.startBroadcast();

        // Address of the deployed ReentrancyExploit contract
        address payable reentrancyExploitAddress = payable(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );

        // Create an instance of the ReentrancyExploit contract
        reentrancyExploit exploit = reentrancyExploit(
            payable(reentrancyExploitAddress)
        );

        // Check the balance of the ReentrancyExploit contract
        uint256 balance = address(exploit).balance;

        console.log("ReentrancyExploit contract balance:", balance);

        vm.stopBroadcast();
    }
}
