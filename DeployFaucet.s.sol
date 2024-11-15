// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeployFaucet is Script {
    address public faucet;

    function run() external returns (Faucet) {
        vm.startBroadcast();

        Faucet newFaucet = new Faucet();
        vm.stopBroadcast();

        return newFaucet;
    }
}
