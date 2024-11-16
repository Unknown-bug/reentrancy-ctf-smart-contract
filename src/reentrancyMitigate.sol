// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AssetVaultMitigate is ReentrancyGuard {
    mapping(address => uint256) private _credits;
    mapping(address => uint8) private _sequence;

    bytes32 private constant PART1 =
        0x466c416753776900000000000000000000000000000000000000000000000000;
    bytes32 private constant PART2 =
        0x6e62757200000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PART3 =
        0x6e65486900000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PART4 =
        0x3375504300000000000000000000000000000000000000000000000000000000;

    event BalanceUpdate(bytes32 indexed data, uint256 indexed opcode);
    event TransferLog(bytes32 indexed data, uint256 indexed opcode);

    function enter() public payable nonReentrant {
        require(msg.value >= 0.5 ether, "Min deposit 0.5 ETH");
        _credits[msg.sender] += msg.value;

        _sequence[msg.sender] = (_sequence[msg.sender] + 1) % 5;

        if (_sequence[msg.sender] == 2) {
            emit BalanceUpdate(PART1 ^ bytes32(block.timestamp), 0xA1);
        }
        if (_sequence[msg.sender] == 3) {
            emit BalanceUpdate(PART2 ^ bytes32(block.timestamp), 0xB2);
        }
    }

    function exit(uint256 _amount) public nonReentrant {
        require(_credits[msg.sender] >= _amount, "Insufficient balance");
        _credits[msg.sender] -= _amount; // Effect

        (bool success, ) = msg.sender.call{value: _amount}(""); // Interaction
        require(success, "Transfer failed");

        uint8 currentSeq = _sequence[msg.sender];
        if (currentSeq == 4 && address(this).balance <= 3 ether) {
            emit TransferLog(
                PART3 ^ bytes32(uint256(uint160(msg.sender))),
                0xC3
            );
        }
        if (address(this).balance <= 1 ether) {
            emit TransferLog(PART4 ^ bytes32(block.timestamp), 0xD4);
        }

        bytes32 flag = PART1 ^ PART2 ^ PART3 ^ PART4;
        require(
            keccak256(abi.encodePacked(flag)) ==
                keccak256(abi.encodePacked(PART1 ^ PART2 ^ PART3 ^ PART4)),
            "Congratulations!"
        );
    }

    function checkBalance(address user) public view returns (uint256) {
        return _credits[user];
    }
}
