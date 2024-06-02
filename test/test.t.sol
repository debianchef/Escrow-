// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow escrow;
    address admin = address(0x1);
    address payable receiver1 = payable(address(0x2));
    address payable receiver2 = payable(address(0x3));
    address depositor1 = address(0x4);
    address depositor2 = address(0x5);
    uint256 amount1 = 5 ether;
    uint256 amount2 = 3 ether;

    function setUp() public {
        // Mock the deployment of the Escrow contract
        vm.startPrank(admin);
        escrow = new Escrow(admin);

        // Fund the depositors with some ether
        vm.deal(depositor1, 30 ether);
        vm.deal(depositor2, 20 ether);
        vm.stopPrank();
    }

    function testSetReceiver() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);
        assertEq(escrow.receivers(depositor1), receiver1);

        vm.prank(depositor2);
        escrow.setReceiver(receiver2);
        assertEq(escrow.receivers(depositor2), receiver2);
    }

    function testDeposit() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        (uint256 depositAmount, bool fundsReleased) = escrow.deposits(depositor1);
        assertEq(depositAmount, amount1);
        assertEq(fundsReleased, false);
        assertEq(address(depositor1).balance, 25 ether);
    }

    function testMultipleDeposits() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        vm.prank(depositor2);
        escrow.setReceiver(receiver2);

        vm.prank(depositor2);
        escrow.deposit{value: amount2}(amount2);

        (uint256 depositAmount1, bool fundsReleased1) = escrow.deposits(depositor1);
        assertEq(depositAmount1, amount1);
        assertEq(fundsReleased1, false);

        (uint256 depositAmount2, bool fundsReleased2) = escrow.deposits(depositor2);
        assertEq(depositAmount2, amount2);
        assertEq(fundsReleased2, false);
    }

    function testReleaseFunds() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        uint initialBalance = receiver1.balance;

        vm.prank(depositor1);
        escrow.releaseFunds();

        (uint256 depositAmount, bool fundsReleased) = escrow.deposits(depositor1);
        assertEq(receiver1.balance, initialBalance + amount1);
        assertEq(fundsReleased, true);
        assertEq(depositAmount, 0);
    }

    function testRefund() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        uint initialBalance = depositor1.balance;

        vm.prank(admin);
        escrow.refund(depositor1);

        (uint256 depositAmount, bool fundsReleased) = escrow.deposits(depositor1);
        assertEq(depositor1.balance, initialBalance + amount1);
        assertEq(depositAmount, 0);
        assertEq(fundsReleased, true);
    }

    function testFailDepositWithoutReceiver() public {
        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);
    }

    function testFailReleaseFundsNotDepositor() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        vm.prank(depositor2);
        escrow.releaseFunds();
    }

    function testFailRefundNotAdmin() public {
        vm.prank(depositor1);
        escrow.setReceiver(receiver1);

        vm.prank(depositor1);
        escrow.deposit{value: amount1}(amount1);

        vm.prank(depositor1);
        escrow.refund(depositor1);
    }
}
