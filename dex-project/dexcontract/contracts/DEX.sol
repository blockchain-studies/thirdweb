// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract DEX is ERC20Base {
    address public owner;
    address public token;

    event DepositEvent(address indexed from, uint256 amount);
    event WithdrawEvent(address indexed to, uint256 amount);
    event AddLiquidityEvent(address indexed from, uint256 amount);
    event RemoveLiquidityEvent(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function!");
        _;
    }

    constructor(
        address _token,
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    ) ERC20Base(_defaultAdmin, _name, _symbol) {
        token = _token;
        owner = msg.sender;
    }

    function getTokensInContract() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function deposit(uint256 _amount) public payable {
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function addLiquidity(uint256 _amount) public payable {
        uint256 balance = address(this));
    }
}
