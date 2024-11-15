// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployFaucet} from "../script/DeployFaucet.s.sol";
import {Faucet} from "../src/Faucet.sol";

contract FaucetTest is Test {
    DeployFaucet public deployFaucet;
    Faucet public faucet;

    function setup() public {
        deployFaucet = new DeployFaucet();
        faucet = deployFaucet.run();
    }

    function test_setUp() public view {
        console.log(address(faucet));
    }
}
