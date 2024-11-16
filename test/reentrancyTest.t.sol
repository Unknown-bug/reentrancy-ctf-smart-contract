// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/reentracy.sol";
import "../src/reentrancyExploit.sol";

contract ReentrancyTest is Test {
    AssetVault public vault;
    reentrancyExploit public exploiter;
    address public attacker = makeAddr("attacker");

    event BalanceUpdate(bytes32 indexed data, uint256 indexed opcode);
    event TransferLog(bytes32 indexed data, uint256 indexed opcode);

    function setUp() public {
        // Deploy contracts
        vault = new AssetVault();
        exploiter = new reentrancyExploit(address(vault));

        // Fund attacker
        vm.deal(attacker, 5 ether);

        // Pre-fund the vault to make flag parts visible
        vm.deal(address(vault), 4 ether);
    }

    function testReentrancyAttack() public {
        // Record initial states
        uint256 initialVaultBalance = address(vault).balance;
        uint256 initialAttackerBalance = address(attacker).balance;

        // Start attack
        vm.startPrank(attacker);

        // Deposit and trigger attack
        exploiter.attack{value: 0.5 ether}();

        // Withdraw stolen funds
        exploiter.withdraw();

        vm.stopPrank();

        // Verify attack success
        assertTrue(
            address(vault).balance < initialVaultBalance,
            "Vault was drained"
        );
        assertTrue(
            address(attacker).balance > initialAttackerBalance,
            "Attacker profited"
        );

        // Log the balances for analysis
        console.log("Initial vault balance:", initialVaultBalance);
        console.log("Final vault balance:", address(vault).balance);
        console.log("Initial attacker balance:", initialAttackerBalance);
        console.log(
            "Attacker's profit:",
            address(attacker).balance - initialAttackerBalance
        );
        console.log("Attacker's balance:", address(attacker).balance);
        console.log("Exploiter's balance:", address(exploiter).balance);
    }

    receive() external payable {}
}
