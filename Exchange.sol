// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IFactory.sol";
import "./IExchange.sol";

contract Exchange is ERC20 {

    address public tokenAddress;
    address public factory;

    constructor(address _token) ERC20("DiscoSwap-V1", "Disco-V1") {
        require(_token != address(0), "Bad address token");
        tokenAddress = _token;
        factory = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        if (getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }

    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserve");
        uint256 inputamoutfee = inputAmount * 99;
        uint256 numenator = outputReserve * inputamoutfee;
        uint256 denumenator = (inputReserve * 100) + inputamoutfee;
        return numenator / denumenator;   
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256){
        require(_ethSold > 0, "ethSold very small");
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256){
        require(_tokenSold > 0, "tokenSold very small");
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokensBought >= _minTokens, "not enough output");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {

        ethToToken(_minTokens, msg.sender);

    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {

        ethToToken(_minTokens, _recipient);


    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        require(ethBought >= _minEth, "not enough output");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
    }

    function tokenToTokenSwap(uint256 _tokenSold, uint256 _minTokensBought, address _token, address _exchangeAddress) public {

        address exchangeAddress = IFactory(factory).getExchange(_token);
        require(exchangeAddress != address(this) && exchangeAddress != address(0));

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        IERC20(_token).transferFrom(msg.sender, address(this), _tokenSold);

        IExchange(_exchangeAddress).ethToTokenTransfer{value: ethBought}(_minTokensBought, msg.sender);

    }

}
