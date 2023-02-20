//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./TokenRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Fee is TokenRegistry{

    mapping(bytes32 => uint) public suppliedLiquidity;
    mapping(bytes32 => uint) public lpFeePool;
    mapping(bytes32 => uint) public ipFeePool;
    mapping(address => mapping(bytes32 => uint)) public liquidityProvider;
    mapping(address => mapping(bytes32 => uint)) public lpFee2Withdraw;

    mapping(bytes32 => uint) internal equilibriumFee; // 20 basis points(1/100 percent) which means 0.2%(20/100)
    mapping(bytes32 => uint) public liquidityFactor;
    uint256 private BASE_DIVISOR = 1000000;
    uint256 private FEE_DIVISOR = 10000;
    uint256 private BASE_FACTOR = 10**18;


    function getSuppliedLiquidity(bytes32 toSymbol) public view returns (uint count) {
       return suppliedLiquidity[toSymbol];
    }

    function getLiquidity(address user, bytes32 symbol) public view returns (uint count) {
       return liquidityProvider[user][symbol];
    } 

    function withdrawLiquidityFee(address to, bytes32 fiatSymbol) internal fiatTokenExist(fiatSymbol) {
     uint feeAccruced;
     uint share;
     (feeAccruced, share)= getLiquidityFeeAccruced(to,fiatSymbol);
     require(feeAccruced >= 0 , "reward amount is too low to withdraw at this momemnt");
     ERC20(fiatTokens[fiatSymbol].tokenAddress).transfer(to, feeAccruced);
    }

    function getLiquidityFeeAccruced(address to, bytes32 fiatSymbol) public fiatTokenExist(fiatSymbol) view returns(uint feeEarned, uint shareEarned) {
       require(suppliedLiquidity[fiatSymbol]>0 , "supplied liquidity is zero");
       uint feeAccrued = (liquidityProvider[to][fiatSymbol]*lpFeePool[fiatSymbol])/(suppliedLiquidity[fiatSymbol]);
       uint share = (liquidityProvider[to][fiatSymbol]*BASE_FACTOR)/(suppliedLiquidity[fiatSymbol]);
       return (feeAccrued,share);
    } 

        // Transfer fee calculations

    function calculateFee(uint destinationAmount, bytes32 destinationSymbol) public onlyAdmin view returns(uint totalFee) {
        require(fiatTokens[destinationSymbol].tokenAddress != address(0), "token does not exist");
        
        uint currentLiquidity;
        uint equiFee ;

            if (equilibriumFee[destinationSymbol] < 20)
                equiFee = 20;
            else            
		        equiFee = equilibriumFee[destinationSymbol];


        currentLiquidity = ERC20(fiatTokens[destinationSymbol].tokenAddress).balanceOf(address(this)) - destinationAmount;
        
        if (currentLiquidity >= suppliedLiquidity[destinationSymbol])
            return (equiFee);
        else {
            uint r;
            if (liquidityFactor[destinationSymbol] < 2)
                r =2;
            else            
                r = liquidityFactor[destinationSymbol];

            uint x = ((suppliedLiquidity[destinationSymbol] - currentLiquidity)*BASE_DIVISOR)/suppliedLiquidity[destinationSymbol];
            uint feesInBasisPoints = equiFee*((1000+((x*1000)/BASE_DIVISOR))**r)/(BASE_DIVISOR*(1000**(r-2)));
            return (feesInBasisPoints);
        }
        
    }

    function calculateFeeAndCashback(uint sourceAmount, bytes32 sourceSymbol, uint destinationAmount, bytes32 destinationSymbol) public onlyAdmin view returns(uint totalFee, uint cashback) {
        uint cashBack = cashbackIPFees(sourceAmount,sourceSymbol);
        uint transactionFee = calculateFee(destinationAmount,destinationSymbol);
        return (transactionFee,cashBack);
    }

    function cashbackIPFees(uint sourceAmount, bytes32 sourceSymbol) public onlyAdmin view returns(uint cashback) {
        uint currentLiquidity;
        uint sLcLdiff;
        uint cashbackFee;
        require(fiatTokens[sourceSymbol].tokenAddress != address(0), "token does not exist");
        currentLiquidity = ERC20(fiatTokens[sourceSymbol].tokenAddress).balanceOf(address(this));
		
        if (suppliedLiquidity[sourceSymbol] > currentLiquidity)
        {
		  sLcLdiff = suppliedLiquidity[sourceSymbol]-currentLiquidity;        
            if (sourceAmount > sLcLdiff)
                return ipFeePool[sourceSymbol];
            else {
                cashbackFee = (sourceAmount*ipFeePool[sourceSymbol])/sLcLdiff;
            }
        }
        return cashbackFee;
    }

    function calculateFeeInAmount(uint sourceAmount, uint destinationAmount, bytes32 destinationSymbol) public onlyAdmin view returns(uint totalFeeAmount) {
        uint totalFee = calculateFee(destinationAmount,destinationSymbol);
        return ((10000+totalFee)*sourceAmount)/10000;
    }

    function getLPFee(bytes32 symbol) public view returns(uint val){
        return lpFeePool[symbol];
    }

}