//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig.NetworkConfig config;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event PlayerEntered(address indexed player, uint256 indexed amount, uint256 totalPlayedAmount);

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, config) = deployRaffle.deployContractRaffle();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitiateRaffleState() public view {
        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    function testRaffleInitiatePlayersAmount() public view {
        assertEq(raffle.getPlayers().length, 0);
    }

    function testRaffleInitiateTotalPlayedAmount() public view {
        assertEq(raffle.getTotalPlayedAmount(), 0);
    }

    function testRaffleRevertWhenDontPayEnought() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughFundsSendedToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();
        assertEq(raffle.getPlayers().length, 1);
    }

    function testRaffleEmitsEventWhenPlayerEnter() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, true, false, false, address(raffle));
        emit PlayerEntered(PLAYER, 1 ether, 1 ether);
        raffle.enterRaffle{value: 1 ether}();
    }

    function testDontAllowPlayersToEnterWhileCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + 30 +1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__NotEnoughTimePassed.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();
    }
}
