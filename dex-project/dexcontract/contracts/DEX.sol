// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DEX is ERC20Base, ReentrancyGuard {
    address public token;

    event DepositEvent(address indexed from, uint256 amount);
    event WithdrawEvent(address indexed to, uint256 amount);
    event AddLiquidityEvent(address indexed from, uint256 amount);
    event RemoveLiquidityEvent(address indexed to, uint256 amount);
    event SwapEthToTokenEvent(address indexed from, address indexed to, uint256 amount);
    event SwapTokenToEthEvent(address indexed from, uint256 amount);

    modifier amountGreaterThanZero(uint256 _amount){
        require(_amount > 0, "Amount must be greater than zero!");
        _;
    }

    constructor(
        address _token,
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    ) ERC20Base(_defaultAdmin, _name, _symbol) {
        token = _token;
    }

    function getTokensInContract() public view returns (uint256) {
        return ERC20Base(token).balanceOf(address(this));           
    }

    function deposit(uint256 _amount) public amountGreaterThanZero(_amount) payable {
        ERC20Base(token).transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);

        emit DepositEvent(msg.sender, _amount);
    }

    function addLiquidity(uint256 _amount) public amountGreaterThanZero(_amount) nonReentrant payable returns (uint256) {
        uint256 _liquidity;
        uint256 balanceInEth = address(this).balance;
        uint256 tokenReserve = getTokensInContract();

        if (tokenReserve == 0) {
            ERC20Base(token).transferFrom(msg.sender, address(this), _amount);
            _liquidity = balanceInEth;
            _mint(msg.sender, _amount);
        } else {
            uint256 ethReserve = balanceInEth - msg.value;

            require(
                _amount >= (msg.value * tokenReserve) / ethReserve,
                "Amouny of tokens sent is less than the minimum required!"
            );

            ERC20Base(token).transferFrom(msg.sender, address(this), _amount);

            unchecked {
                _liquidity = (totalSupply() * tokenReserve) / ethReserve;
            }

            _mint(msg.sender, _liquidity);
        }

        emit AddLiquidityEvent(msg.sender, _amount);

        return _liquidity;
    }

    function removeLiquidity(uint256 _amount) public amountGreaterThanZero(_amount) nonReentrant returns (uint256, uint256) {
        uint256 _reservedEth = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 _ethAmount = (_amount * _reservedEth) / _totalSupply;
        uint256 _tokenAmount = (_amount * getTokensInContract()) / _totalSupply;

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_ethAmount);
        ERC20Base(token).transfer(msg.sender, _tokenAmount);

        emit RemoveLiquidityEvent(msg.sender, _amount);

        return (_ethAmount, _tokenAmount);
    }

    function getAmountOfTokens(uint256 _amount, uint256 _inputReserve, uint256 _outputReserve) public pure returns (uint256) {
        require(_inputReserve > 0 && _outputReserve > 0, "Reserve must be greater than zero!");

        uint256 _amountWithFee = _amount * 99;
        uint256 _numerator = _amountWithFee * _outputReserve;
        uint256 _denominator = (_inputReserve * 100) + _amountWithFee;

        unchecked {
            return _numerator / _denominator;
        }
    }

    function swapEthToToken() public payable {
        uint256 _tokenReserve = getTokensInContract();
        uint256 _ethReserve = address(this).balance;
        uint256 _tokenAmount = getAmountOfTokens(msg.value, _ethReserve, _tokenReserve);

        ERC20Base(token).transfer(msg.sender, _tokenAmount);

        emit SwapEthToTokenEvent(address(this), msg.sender, _tokenAmount);    
    }

    function swapTokenToEth(uint256 _amount) public amountGreaterThanZero(_amount) {
        uint256 _tokenReserve = getTokensInContract();
        uint256 _ethReserve = address(this).balance;
        uint256 _ethBought = getAmountOfTokens(_amount, _tokenReserve, _ethReserve);

        ERC20Base(token).transferFrom(msg.sender, address(this), _amount);
        payable(msg.sender).transfer(_ethBought);

        emit SwapTokenToEthEvent(msg.sender, _ethBought);
    }
}
