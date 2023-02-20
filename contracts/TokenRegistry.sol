pragma solidity ^0.8.4;


contract TokenRegistry{

    struct Token {
        bytes32 symbol;
        address tokenAddress;
    }

    address public admin;

    mapping(bytes32 => Token) public fiatTokens;
    mapping(bytes32 => Token) public lpTokens;
    bytes32[] public fiatTokenList;
    bytes32[] public lpTokenList;

    // Add fiat token contract address to registry
    function addFiatToken(bytes32 symbol, address tokenAddress) public onlyAdmin{
        fiatTokens[symbol] = Token(symbol, tokenAddress);
        fiatTokenList.push(symbol);
    }

    // get token contract address from registry
    function getFiatTokens() external view returns(Token[] memory) {
      Token[] memory _tokens = new Token[](fiatTokenList.length);
      for (uint i = 0; i < fiatTokenList.length; i++) {
        _tokens[i] = Token(
          fiatTokens[fiatTokenList[i]].symbol,
          fiatTokens[fiatTokenList[i]].tokenAddress
        );
      }
      return _tokens;
    }

    // Add LP token contract address to registry
    function addLPToken(bytes32 symbol, address tokenAddress) public onlyAdmin{
        lpTokens[symbol] = Token(symbol, tokenAddress);
        lpTokenList.push(symbol);
    } 

    // get LP token contract address from registry
    function getLPTokens() external view returns(Token[] memory) {
      Token[] memory _tokens = new Token[](lpTokenList.length);
      for (uint i = 0; i < fiatTokenList.length; i++) {
        _tokens[i] = Token(
          lpTokens[lpTokenList[i]].symbol,
          lpTokens[lpTokenList[i]].tokenAddress
        );
      }
      return _tokens;
    }

    // onlyAdmin Modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    // fiatToken exist checking modifier
    modifier fiatTokenExist(bytes32 symbol) {
        require(
            fiatTokens[symbol].tokenAddress != address(0), "fiat token does not exist"
        );
        _;
    }

    // lpToken exist checking modifier
    modifier lpTokenExist(bytes32 symbol) {
        require(
            lpTokens[symbol].tokenAddress != address(0), "LP token does not exist"
        );
        _;
    }
}