// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/reentrancyMitigate.sol";

contract FlagExtractorTest is Test {
    AssetVaultMitigate public vault;
    address public player = address(0x1);
    uint256 public constant DEPOSIT_AMOUNT = 0.5 ether;

    event BalanceUpdate(bytes32 indexed data, uint256 indexed opcode);
    event TransferLog(bytes32 indexed data, uint256 indexed opcode);

    function setUp() public {
        vault = new AssetVaultMitigate();
        vm.deal(player, 10 ether);
    }

    function testExtractFlag() public {
        bytes32 part1;
        bytes32 part2;
        bytes32 part3;
        bytes32 part4;

        vm.startPrank(player);

        // To get PART1 and PART2, we need sequence to be 2 and 3
        // Each deposit increments sequence by 1
        vm.recordLogs();

        // First deposit - sequence becomes 1
        vault.enter{value: DEPOSIT_AMOUNT}();

        // Second deposit - sequence becomes 2, should emit PART1
        vault.enter{value: DEPOSIT_AMOUNT}();

        // Third deposit - sequence becomes 3, should emit PART2
        vault.enter{value: DEPOSIT_AMOUNT}();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics.length >= 3) {
                if (uint256(entries[i].topics[2]) == 0xA1) {
                    part1 = entries[i].topics[1] ^ bytes32(block.timestamp);
                }
                if (uint256(entries[i].topics[2]) == 0xB2) {
                    part2 = entries[i].topics[1] ^ bytes32(block.timestamp);
                }
            }
        }

        // Now we need sequence to be 4 and balance <= 3 ether for PART3
        // Fourth deposit - sequence becomes 4
        vault.enter{value: DEPOSIT_AMOUNT}();

        vm.recordLogs();
        // Withdraw enough to get balance <= 3 ether
        vault.exit(1.5 ether);

        entries = vm.getRecordedLogs();
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics.length >= 3) {
                if (uint256(entries[i].topics[2]) == 0xC3) {
                    part3 =
                        entries[i].topics[1] ^
                        bytes32(uint256(uint160(player)));
                }
            }
        }

        vm.recordLogs();
        // Withdraw more to get balance <= 1 ether for PART4
        vault.exit(0.5 ether);

        entries = vm.getRecordedLogs();
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics.length >= 3) {
                if (uint256(entries[i].topics[2]) == 0xD4) {
                    part4 = entries[i].topics[1] ^ bytes32(block.timestamp);
                }
            }
        }

        // Reconstruct the flag
        bytes32 flag = part1 ^ part2 ^ part3 ^ part4;

        // Convert bytes32 to string - only showing first 32 bytes as that's where the flag should be
        emit log_string(string(abi.encodePacked(flag)));

        vm.stopPrank();
    }
}
