// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { Handler } from "./Handler.t.sol";

contract Invariant is Test {
    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;

    Handler handler;

    // for pool
    int256 constant STARTING_X = 100e18;
    int256 constant STARTING_Y = 50e18;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();

        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // create the inital x and y values for the pool

        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        //deposit into the pool, give the starting X and Y values
        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameX() public {
        // assert() ?
        // the change in the pool size of weth should follow this function
        // ∆x = (β/(1-β)) * x
        // ∆y = (α/(1+α)) * y
        // in a hanlder
        // actual delta X == ∆x = (β/(1-β)) * x
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

     function statefulFuzz_constantProductFormulaStaysTheSameY() public {
        // assert() ?
        // the change in the pool size of weth should follow this function
        // ∆x = (β/(1-β)) * x
        // ∆y = (α/(1+α)) * y
        // in a hanlder
        // actual delta X == ∆x = (β/(1-β)) * x
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}
