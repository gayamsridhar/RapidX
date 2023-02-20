// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Fee.sol";

contract RapidX is ERC20, Fee{

    ERC20 public token;

    // RapidX constructor
    constructor(string memory name, string memory symbol) ERC20(name,symbol) {
        admin = msg.sender;
    }

    event AddLiquidity(uint amount, address to, bytes32 fiatSymbol, bytes32 lpSymbol);
    event WithdrawLiquidity(uint amount, address to, bytes32 fiatSymbol);
    event TransferFiat(uint amount, address to, bytes32 destinationFiatSymbol);

    // supply liquidity to Rapid Pool Contract
    // 1. user will send his fiat tokens to contract (tokensnised FIat : Transfer function ) - Amount
    // 2. addLiquidity by admin to transfer LP tokens from Contract to USER

    function addLiquidity(uint amount, address to, bytes32 fiatSymbol, bytes32 lpSymbol, uint ratio) public fiatTokenExist(fiatSymbol) lpTokenExist(lpSymbol){
        uint allowanceAmount = ERC20(fiatTokens[fiatSymbol].tokenAddress).allowance(to, address(this));
        require(allowanceAmount>=amount, "amount is greater than allowance amount");
        ERC20(fiatTokens[fiatSymbol].tokenAddress).transferFrom(to,address(this),amount*ratio);
        ERC20(lpTokens[lpSymbol].tokenAddress).transfer(to, amount*ratio);
        suppliedLiquidity[fiatSymbol] += amount;  
        liquidityProvider[to][fiatSymbol]+= amount;

        emit AddLiquidity(amount,to,fiatSymbol,lpSymbol);   
    }

    function withdrawLiquidity(uint amount, address to, bytes32 fiatSymbol, bytes32 lpSymbol) public fiatTokenExist(fiatSymbol) {
        uint allowanceLpAmount = ERC20(lpTokens[lpSymbol].tokenAddress).allowance(to, address(this));
        
        require(allowanceLpAmount>=amount, "withdrawl amount is greater than allowance amount");
        ERC20(lpTokens[lpSymbol].tokenAddress).transferFrom(to,address(this),amount);
        
        require(liquidityProvider[to][fiatSymbol] >= amount , "Withdrawal amount requested is more than supplied liquidity");
        ERC20(fiatTokens[fiatSymbol].tokenAddress).transfer(to, amount);     

        withdrawLiquidityFee(to,fiatSymbol);

        suppliedLiquidity[fiatSymbol] -= amount;
        liquidityProvider[to][fiatSymbol]-= amount;

        emit WithdrawLiquidity(amount,to,fiatSymbol); 
    }

    
    function transferFiat(address to, uint destinationAmount, bytes32 destinationFiatSymbol, uint sourceAmount, bytes32 sourceFiatSymbol) public fiatTokenExist(destinationFiatSymbol) onlyAdmin {
            uint equiFee ;

            if (equilibriumFee[destinationFiatSymbol] < 20)
                equiFee = 20;
            else            
		        equiFee = equilibriumFee[destinationFiatSymbol];
                
        uint cashBack = cashbackIPFees(sourceAmount,sourceFiatSymbol);
        uint transactionFee = calculateFee(destinationAmount,destinationFiatSymbol);
        uint ipFee = transactionFee-equiFee;

     ipFeePool[sourceFiatSymbol] -= cashBack;

     lpFeePool[destinationFiatSymbol] +=(equiFee*destinationAmount)/10000;

     ipFeePool[destinationFiatSymbol] += (ipFee*destinationAmount)/10000;

     // notificationToSeller(to,destinationAmount,destinationFiatSymbol);     

     ERC20(fiatTokens[destinationFiatSymbol].tokenAddress).transfer(to, destinationAmount);

      emit TransferFiat(destinationAmount, to, destinationFiatSymbol);
    } 




}