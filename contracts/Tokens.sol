// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tokens is ERC20{

  address public tokenAdmin;
    
  constructor(string memory name, string memory symbol,  uint adminSupply) ERC20(name,symbol) {
    tokenAdmin = msg.sender;
    _mint(msg.sender,adminSupply);
  }

  function tMint(address to, uint amount) external onlyAdmin {
    _mint(to, amount);
  }

  function tBurn(address to, uint amount) external {
       _burn(to, amount);
  }

  modifier onlyAdmin() {
    require(msg.sender == tokenAdmin, "only admin");
    _;
  }
}