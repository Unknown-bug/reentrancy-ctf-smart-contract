// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/reentrancyMitigate.sol";
import "../src/reentrancyExploit.sol";

contract ReentrancyMitigateTest is Test {
    AssetVaultMitigate public target;
    reentrancyExploit public exploit;
    address public attacker = address(0x1);

    function setUp() public {
        target = new AssetVaultMitigate();
        exploit = new reentrancyExploit(address(target));
        vm.deal(attacker, 5 ether);
    }

    function testReentrancyAttack() public {
        vm.deal(address(target), 1 ether);

        vm.startPrank(attacker);
        exploit.attack{value: 1 ether}();
        vm.stopPrank();

        uint256 targetBalance = address(target).balance;
        uint256 exploitBalance = address(exploit).balance;

        console.log("targetBalance: ", targetBalance);
        console.log("exploitBalance: ", exploitBalance);

        // Verify that the reentrancy attack failed
        assertEq(targetBalance, 1 ether, "Target balance should remain intact");
        assertEq(
            exploitBalance,
            0 ether,
            "Exploit contract should not have gained ETH"
        );
    }

    function testMultipleExits() public {
        vm.startPrank(attacker);
        target.enter{value: 2 ether}();
        target.exit(1 ether);
        target.exit(1 ether);
        vm.stopPrank();

        uint256 targetBalance = address(target).balance;
        uint256 attackerBalance = target.checkBalance(attacker);

        assertEq(targetBalance, 0 ether, "Target balance should be zero");
        assertEq(attackerBalance, 0 ether, "Attacker balance should be zero");
    }

    function testEnterAndExit() public {
        vm.startPrank(attacker);
        target.enter{value: 1 ether}();
        uint256 balance = target.checkBalance(attacker);
        assertEq(balance, 1 ether, "Balance should be 1 ether");

        target.exit(1 ether);
        balance = target.checkBalance(attacker);
        assertEq(balance, 0 ether, "Balance should be zero");
        vm.stopPrank();
    }

    function testInsufficientBalanceExit() public {
        vm.startPrank(attacker);
        target.enter{value: 0.5 ether}();
        vm.expectRevert("Insufficient balance");
        target.exit(1 ether);
        vm.stopPrank();
    }

    function testReentrancyGuard() public {
        vm.startPrank(attacker);
        exploit.attack{value: 1 ether}();

        // Attempt to re-enter during exit
        vm.expectRevert("ReentrancyGuard: reentrant call");
        exploit.attack{value: 1 ether}();

        // Additional attempt to re-enter
        vm.expectRevert("ReentrancyGuard: reentrant call");
        exploit.attack{value: 1 ether}();
        vm.stopPrank();
    }
}
