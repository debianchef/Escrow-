// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/Escrow.sol";

contract DeployEscrow is Script {
    function run() external {
        address admin = vm.envAddress("ADMIN_ADDRESS");

        vm.startBroadcast();

        Escrow escrow = new Escrow(admin);

        vm.stopBroadcast();

        console.log("Escrow contract deployed at:", address(escrow));
    }
}