// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/reentrancyMitigate.sol";
import "../src/reentrancyExploitMitigate.sol";

contract AssetVaultTest is Test {
    reentrancyMitigate assetVault;
    reentrancyExploitMitigate exploit;
    address attacker = address(0xBEEF); // Designated attacker address

    // Fund amount
    uint256 depositAmount = 1 ether;

    function setUp() public {
        // Deploy the AssetVault contract
        assetVault = new reentrancyMitigate();

        // Deploy the ReentrancyExploit contract with the AssetVault's address
        exploit = new reentrancyExploitMitigate(address(assetVault));

        // Label addresses for better readability in test logs
        vm.label(address(assetVault), "AssetVault");
        vm.label(address(exploit), "ReentrancyExploit");
        vm.label(attacker, "Attacker");
    }

    function test_Reentrancy_Mitigated() public {
        // Step 1: Attacker deposits 0.5 ETH into AssetVault
        vm.deal(attacker, depositAmount);
        vm.startPrank(attacker);
        exploit.attack{value: 0.5 ether}();

        // Exploit contract should have received 0.5 ETH
        uint256 initialExploitBalance = address(exploit).balance;
        uint256 vaultBalance = assetVault.checkBalance(attacker);

        // Assert initial conditions
        assertEq(
            initialExploitBalance,
            0.5 ether,
            "Exploit contract should have 0.5 ETH after attack"
        );
        assertEq(
            vaultBalance,
            0.0 ether,
            "AssetVault should have 0 ETH for attacker after withdrawal"
        );

        // Step 2: Attempt reentrancy by calling attack again
        (bool success, ) = address(exploit).call{value: 0}(
            abi.encodeWithSignature("attack()")
        );

        // Assert that reentrancy did not occur
        assertEq(
            address(exploit).balance,
            0.5 ether,
            "Exploit contract balance should remain 0.5 ETH"
        );
        assertEq(
            vaultBalance,
            0.0 ether,
            "AssetVault balance for attacker should remain 0 ETH"
        );

        // Additionally, check that the total balance of AssetVault has not been drained
        uint256 totalVaultBalance = address(assetVault).balance;
        assertEq(
            totalVaultBalance,
            0.0 ether,
            "AssetVault total balance should be 0 ETH"
        );

        vm.stopPrank();
    }

    function test_Reentrancy_AttemptFails() public {
        // Step 1: Attacker deposits 1 ETH into AssetVault
        vm.deal(attacker, depositAmount);
        vm.startPrank(attacker);
        exploit.attack{value: 1 ether}();

        // Attempt to exploit again by calling attack
        (bool success, ) = address(exploit).call{value: 0}(
            abi.encodeWithSignature("attack()")
        );

        // Assert that the second attack does not increase the exploit's balance
        uint256 exploitBalance = address(exploit).balance;
        uint256 vaultBalance = assetVault.checkBalance(attacker);

        // Expected: Only the first attack succeeds
        assertEq(
            exploitBalance,
            1 ether,
            "Exploit contract should have only 1 ETH after two attack attempts"
        );
        assertEq(
            vaultBalance,
            0 ether,
            "AssetVault should have 0 ETH for attacker after withdrawal"
        );

        // Check that AssetVault's balance is zero
        uint256 totalVaultBalance = address(assetVault).balance;
        assertEq(
            totalVaultBalance,
            0 ether,
            "AssetVault total balance should be 0 ETH"
        );

        vm.stopPrank();
    }
}
