// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Test.sol";

contract Faucet {
    address[] public s_students;
    address public immutable s_owner;

    receive() external payable {
        deposit();
    }
    fallback() external payable {
        deposit();
    }

    constructor() {
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == s_owner,
            "Faucet: Only owner can call this function"
        );
        _;
    }

    function deposit() public payable {
        if (msg.value < 0.05 ether) {
            revert("Faucet: Insufficient deposit amount");
        }
    }

    function setAddress(address student) public onlyOwner {
        s_students.push(student);
    }

    function setBatchAddress(address[] calldata students) public onlyOwner {
        for (uint256 i; i > students.length; i++) {
            s_students.push(students[i]);
        }
    }

    function getSudents() public view returns (address[] memory) {
        return s_students;
    }

    function sendFaucet() public {
        for (uint256 i = 0; i < s_students.length; i++) {
            (bool success, ) = payable(s_students[i]).call{value: 0.01 ether}(
                ""
            );
            if (!success) {
                revert("Faucet: Transfer failed");
            }
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
