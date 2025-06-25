// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Panagram} from "../src/Panagram.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract PanagramTest is Test {
    HonkVerifier verifier;
    Panagram panagram;

    bytes32 constant ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS)))) % FIELD_MODULUS);
    bytes32 constant CORRECT_GUESS = bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS);
    bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("tranisleg")) % FIELD_MODULUS);
    //bytes proof;
    bytes32[] publicInputs;

    address user = makeAddr("user");
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function setUp() public {
        verifier = new HonkVerifier();
        panagram = new Panagram(verifier);

        panagram.newRound(ANSWER);
        //proof = _getProof(CORRECT_GUESS, ANSWER, user);
    }

    function _getProof(bytes32 guess, bytes32 correctAnswer, address _user) internal returns (bytes memory _proof) {
        uint256 NUM_ARGS = 6;
        string[] memory inputs = new string[](NUM_ARGS);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "../js-scripts/generateProof.ts";
        inputs[3] = vm.toString(guess);
        inputs[4] = vm.toString(correctAnswer);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_user))));


        bytes memory result = vm.ffi(inputs);
        _proof = abi.decode(result, (bytes));
    }

    function testPrintAnswer() public pure {
        console.logBytes32(keccak256("triangles"));
        console.logBytes32(bytes32(uint256(keccak256("triangles"))));
    }

    function testPritAnswer() public pure {
        console.log(uint256(keccak256("triangles")) % FIELD_MODULUS);
        console.log(uint256(keccak256("triangles")));
    }

    function testCorrectGuessPasses() public {
        vm.prank(user);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, user);
        panagram.makeGuess(proof);
        //vm.assertEq(panagram.s_winnerWins(user), 1);
        vm.assertEq(panagram.balanceOf(user, 0), 1);
        vm.assertEq(panagram.balanceOf(user, 1), 0);

        // check they can't try again
        vm.prank(user);
        vm.expectRevert();
        panagram.makeGuess(proof);
    }

    function testSecondGuessPasses() public {
        vm.prank(user);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, user);
        panagram.makeGuess(proof);
        //vm.assertEq(panagram.s_winnerWins(user), 1);
        vm.assertEq(panagram.balanceOf(user, 0), 1);
        vm.assertEq(panagram.balanceOf(user, 1), 0);

        address user2 = makeAddr("user2");
        bytes memory proof2 = _getProof(CORRECT_GUESS, ANSWER, user2);
        vm.prank(user2);
        panagram.makeGuess(proof2);
        //vm.assertEq(panagram.s_winnerWins(user2), 0);
        vm.assertEq(panagram.balanceOf(user2, 0), 0);
        vm.assertEq(panagram.balanceOf(user2, 1), 1);
    }

    function testStartSecondRound() public {
        vm.prank(user);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, user);
        panagram.makeGuess(proof);
        //vm.assertEq(panagram.s_winnerWins(user), 1);
        vm.assertEq(panagram.balanceOf(user, 0), 1);
        vm.assertEq(panagram.balanceOf(user, 1), 0);

        vm.warp(panagram.MIN_DURATION() + 1);
        bytes32 NEW_ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS)))) % FIELD_MODULUS);
        panagram.newRound(NEW_ANSWER);
        vm.assertEq(panagram.s_currentRound(), 2);
        vm.assertEq(panagram.s_currentRoundWinner(), address(0));
        vm.assertEq(panagram.s_answer(), NEW_ANSWER);
    }

    /* function testStartNewRound() public {
        // start a round (in setUp)
        // get a winner
        vm.prank(user);
        bytes memory proof = _getProof(CORRECT_GUESS, ANSWER, user);

        panagram.makeGuess(proof);
        // min time passed
        vm.warp(panagram.MIN_DURATION() + 1);
        // start a new round
        bytes32 NEW_ANSWER = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        panagram.newRound(NEW_ANSWER);
        // validate the state has reset
        vm.assertEq(panagram.s_currentRound(), 2);
        vm.assertEq(panagram.s_currentRoundWinner(), address(0));
        vm.assertEq(panagram.s_answer(), NEW_ANSWER);
    } */

    function testIncorrectGuessFails() public {
        // start a round
        // get hash(?) of guess
        // use script to get proof
        // make a guess call
        // validate they got the winner NFT
        // validate they have been incremented in winnerWins mapping  
        bytes32 INCORRECT_ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS)))) % FIELD_MODULUS);
        bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_ANSWER, user);
        
        //bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_GUESS, user);
        vm.prank(user);
        vm.expectRevert();
        panagram.makeGuess(incorrectProof);
    }
}