// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/reentrancyMitigate.sol";
import "../src/reentrancyExploitMitigate.sol";

contract AssetVaultMitigateTest is Test {
    AssetVaultMitigate public vault;
    reentrancyExploitMitigate public exploiter;
    address public attacker = address(0x3);
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant DEPOSIT_AMOUNT = 0.5 ether;

    function setUp() public {
        // Setup initial balances
        vm.deal(attacker, INITIAL_BALANCE);
        // Deploy contracts
        vault = new AssetVaultMitigate();
        exploiter = new reentrancyExploitMitigate(address(vault));
    }

    // Basic deposit test to ensure the contract works normally
    function testBasicDeposit() public {
        vm.startPrank(attacker);
        vault.enter{value: DEPOSIT_AMOUNT}();
        assertEq(vault.checkBalance(attacker), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    // Basic withdrawal test
    function testBasicWithdraw() public {
        vm.startPrank(attacker);
        vault.enter{value: DEPOSIT_AMOUNT}();
        uint256 balanceBefore = address(attacker).balance;
        vault.exit(DEPOSIT_AMOUNT);
        assertEq(address(attacker).balance, balanceBefore + DEPOSIT_AMOUNT);
        assertEq(vault.checkBalance(attacker), 0);
        vm.stopPrank();
    }

    // Test reentrancy attack prevention
    function testReentrancyAttackPrevention() public {
        vm.deal(address(vault), INITIAL_BALANCE);
        console.log(
            "Attacker balance before attack:",
            address(attacker).balance
        );

        console.log("Vault balance before attack:", address(vault).balance);
        console.log(
            "Exploiter balance before attack:",
            address(exploiter).balance
        );

        // Initial state
        vm.startPrank(attacker);

        // Initial deposit from attacker
        exploiter.attack{value: DEPOSIT_AMOUNT}();

        console.log(
            "Attacker balance after attack:",
            address(attacker).balance
        );
        console.log("Vault balance after attack:", address(vault).balance);
        console.log(
            "Exploiter balance after attack:",
            address(exploiter).balance
        );

        // Check that the exploiter contract's balance in the vault remains consistent
        assertEq(
            address(exploiter).balance,
            DEPOSIT_AMOUNT,
            "Exploiter should have attacker's deposit"
        );

        // Verify that no additional withdrawals were processed
        assertEq(
            address(vault).balance,
            INITIAL_BALANCE,
            "Vault balance should remain unchanged after failed attack"
        );

        vm.stopPrank();
    }

    receive() external payable {}
}
