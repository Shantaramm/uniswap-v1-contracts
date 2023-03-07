
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Exchange.sol";

contract Factory {

    mapping(address => address) public tokenExchange;

    function createExchange (address _token) public returns (address) {

        require(_token != address(0), "invalid address");
        require(tokenExchange[_token] == address(0), "exchange was created");
        Exchange ex = new Exchange(_token);
        tokenExchange[_token] = address(ex);
        return address(ex);
    }

    function getExchange(address _token) view public returns (address) {

        return tokenExchange[_token];
    }

}
