// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract CurrencyExchange {
    IERC20 public stableCoin; // e.g. LMC

    // your variables
    mapping(string => IERC20) public currencies;
    mapping(string => AggregatorV3Interface) public oracles;
    //mapping(string =>uint256) public liquidity;

    event Swap ( address user , string pair , uint256 inAmt , uint256 outAmt ) ;
    event LiquidityAdded ( address user , string symbol , uint256 amount ) ;
    event Debug ( string msg , uint256 val ) ;


    constructor(address _stableCoin) {
        // your constructor
        stableCoin = IERC20(_stableCoin);
    }

    // Register currency + oracle
    function addCurrency(string memory symbol, address token, address oracle) external {
        // your implementation
        require(bytes(symbol).length>0,"invalid symbol");
        require(token !=address(0),"invalid token");
        require(oracle != address(0), "invalid oracle");
        currencies[symbol] = IERC20(token);
        oracles[symbol] = AggregatorV3Interface(oracle);
    }

    // View balances
    function balanceOf(string memory symbol) external view returns (uint256) {
        // your implementation
        require(address(currencies[symbol]) != address(0), "currency not registered");
        return currencies[symbol].balanceOf(address(this));
        
    }

    function stableBalance() external view returns (uint256) {
        // your implementation
        return stableCoin.balanceOf(address(this));
    }

    // Add liquidity in stable
    function addLiquidityStable(uint256 amount) external {
        // your implementation
        bool check;
        check = stableCoin.transferFrom(msg.sender,address(this), amount);
        require(check ==true,"Stable transfer failed");
        //liquidity["LMC"] +=amount;
        emit LiquidityAdded(msg.sender, "LMC", amount);
    }

    // Add liquidity in any token
    function addLiquidity(string memory symbol, uint256 amount) external {
        // your implementation
        require(address(currencies[symbol]) != address(0), "currency not registered" );
        bool check = currencies[symbol].transferFrom(msg.sender,address(this),amount);
        require(check==true,"currrency transfer failed");
        //liquidity[symbol] += amount;
        emit LiquidityAdded(msg.sender, symbol, amount);
        
    }
    function getLatestPrice ( string memory symbol ) public view returns ( int ) {
        (, int price , , ,) = oracles [ symbol ]. latestRoundData () ;
        return price ; // e . g . 4243.7122 * 1 e8
    }

    // Swap LMC -> Token
    function swapStableToCurrency(string memory symbol, uint256 amount) external {
        // your implementation
        require(address(currencies[symbol]) != address(0), "currency not registered");
        bool check=  stableCoin.transferFrom(msg.sender, address(this), amount);
        require(check==true,"Stable transfer failed");
        //liquidity["LMC"] +=amount;

        int price = getLatestPrice(symbol);
        require(price>0,"Invalid price");
        uint256 output = (amount*(10**(oracles[symbol].decimals())))/ (uint256(price));

        require(currencies[symbol].balanceOf(address(this)) >=output,"Not enough liquidity");
        bool check1 = currencies[symbol].transfer( msg.sender, output);
        require(check1 == true, "currency transfer failed");
        //liquidity[symbol] = liquidity[symbol] - output;
        emit Swap(msg.sender, "LMC->ETH", amount, output);

    }

    // Swap Token -> LMC
    function swapCurrencyToStable(string memory symbol, uint256 amount) external {
        // your implementation
        require(address(currencies[symbol]) != address(0),"");
        bool check = currencies[symbol].transferFrom(msg.sender,address(this),amount);
        require(check==true, "currency transfer failed");

        //liquidity[symbol] = liquidity[symbol]+amount;

        int price = getLatestPrice(symbol);
        require(price>0,"Invalid price");
        uint256 output = (amount*uint256(price))/ (10**(oracles[symbol].decimals()));

        require(stableCoin.balanceOf(address(this))>=output, "Not enough liquidity");
        bool check1 = stableCoin.transfer(msg.sender,output);
        require(check1==true,"Stable transfer failed");
        //liquidity["LMC"] -=output;
        emit Swap(msg.sender, "ETH->LMC", amount, output);

    }
}