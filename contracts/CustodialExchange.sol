// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CurrencyExchange.sol";


contract CustodialExchange is CurrencyExchange {
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    // TODO: Define your state variables here
    // 
    // You need to track:
    // 1. User accounts (existence, KYC status, KYC hash, creation time)
    // 2. User balances (total per currency, per-wallet balances for wallet assignment)
    // 3. Exchange wallets (addresses, active status, reserves per currency)
    // 4. Token registrations (token address, oracle, issuer, total custodial supply)
    // 5. Owner address
    // 6. Wallet ID counter
    // 7. Total users counter
    //
    // IMPORTANT: You have complete freedom in how you structure these.
    // You can use structs, mappings, arrays, or any combination.

    // Choose a structure that allows you to:
    // - Track all required information
    // - Implement all view functions correctly
    // - Support all required operations efficiently

    address public owner;
    uint256 public nextWalletId;
    uint256 public totalUsers;
    // TODO: Add your own state variables for accounts, balances, wallets, registrations
    // exists, isKycVerified, createdAt = bool, bool, uint256
                             // accounts // 
    // // account existence 
    // mapping(address => mapping (string => bool)) public exists;
    // // kyc verification
    // mapping(address => mapping (string => bool)) public isKycVerified;
    // // timestamp creation
    // mapping(address => mapping (string => uint256)) public createdAt;
    // // kyc hash
    // mapping(address => mapping (string => bytes32)) public KYChash;
    // or struct????
    struct ACCdetails {
        bool exists;
        bool isKycVerified;
        bytes32 KYChash;
        uint256 createdAt;
    }
    // user address => accDetails
    mapping (address => ACCdetails) public userAccounts;

    // user -> currency -> balance
    mapping (address => mapping(string => uint256)) public userBalance; //custodial balance?
    // user -> walletid -> currency -> balance
    mapping (address => mapping(uint256 => mapping(string => uint256) )) public userBalancePerWallet; //custodial balance?


    struct walletDetails {
        address walletAddress;
        bool isWalletActive;
        // currency to reserves
        mapping(string => uint256) tokenReservesperWallet;
    }
    // wallet id to each wallet struct
    mapping(uint256 => walletDetails) public exchangeWallets;

    // helper wallet address to wallet id
    mapping ( address => uint256) public WalletaddresstoID;
    // // helper user address to wallet ids?
    // mapping(address => uint256) public usertoWalletID;

    struct tokenDetails {
        address tokenContractaddress;
        address oracleAddress;
        address issuerAddress;
        uint256 custodialSupplyPerToken;
    }
    // symbol to tokendetails?
    mapping(string => tokenDetails) public tokenRegistrations;



    event CustodialAccountCreated(address indexed userId, uint256 createdAt);
    event KYCVerified(address indexed user);
    event StablecoinRegistered(string indexed symbol, address indexed issuer, address token);
    event CustodialDeposit(address indexed user, string indexed symbol, uint256 amount, address fromWallet);
    event CustodialWithdrawal(address indexed user, string indexed symbol, uint256 amount, address toWallet);
    event CustodialTransfer(address indexed from, address indexed to, string indexed symbol, uint256 amount);
    event CustodialTrade(address indexed user, string fromSymbol, string toSymbol, uint256 amountIn, uint256 amountOut);
    event WalletCreated(uint256 indexed walletId, address walletAddress);
    
    
    modifier onlyOwner() {
        // TODO: Implement owner check
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier accountExists(address user) {
        // TODO: Check that user account exists
        // You need to implement this based on your state structure
        // Example: require(/* your account existence check */, "Account does not exist");
        require(userAccounts[user].exists == true, "Account does not exist");
        _;

    }
    
    modifier kycVerified(address user) {
        // TODO: Check that user's KYC is verified
        // You need to implement this based on your state structure
        // Example: require(/* your KYC verification check */, "KYC not verified");
        require( userAccounts[user].isKycVerified == true, " KYC not verified");
        _;
    }

    constructor(address _stableCoin) CurrencyExchange(_stableCoin) {
        // TODO: Initialize your state variables
        owner = msg.sender;
        nextWalletId = 1;
        totalUsers = 0;
        // TODO: Initialize any other state variables you declared

    }


    function createExchangeWallet(address walletAddress) external onlyOwner {
        // TODO: Implement wallet creation
        // - Store wallet address
        // - Mark as active
        // - Assign wallet ID
        // - Emit WalletCreated event
        exchangeWallets[nextWalletId].walletAddress = walletAddress;
        exchangeWallets[nextWalletId].isWalletActive = true;

        // maybe
        WalletaddresstoID[walletAddress] = nextWalletId;
        uint256 currentwalletid = nextWalletId;
        nextWalletId = nextWalletId + 1;
        emit WalletCreated(currentwalletid, walletAddress);
    }
    
    function createCustodialAccount(string memory kycInfo) external {
        // TODO: Implement account creation
        require(userAccounts[msg.sender].exists == false, "Account already exists");
        require(bytes(kycInfo).length !=0, " kycinfo is empty");
        bytes32 temphash = keccak256(abi.encodePacked(kycInfo));
        userAccounts[msg.sender].KYChash = temphash;
        userAccounts[msg.sender].exists = true;
        userAccounts[msg.sender].createdAt = block.timestamp;
        totalUsers = totalUsers +1;
        emit CustodialAccountCreated(msg.sender, userAccounts[msg.sender].createdAt);
    }
    

    function verifyKYC(address user, string memory kycInfo) external onlyOwner accountExists(user) {
        // TODO: Implement KYC verification
        require(bytes(kycInfo).length !=0, "kycinfo is empty");
        bytes32 checkhash = keccak256(abi.encodePacked(kycInfo));
        require(checkhash == userAccounts[user].KYChash, "KYC information mismatch");
        userAccounts[user].isKycVerified = true;
        emit KYCVerified(user); 
    }
    

    function registerStablecoin(
        string memory symbol,
        address tokenAddress,
        address oracleAddress,
        string memory issuerKycInfo
    ) external {
        // TODO: Implement stablecoin registration
        // Remember to register it with the exchange as well
        require(tokenRegistrations[symbol].tokenContractaddress == address(0), "token already registered");
        require(bytes(issuerKycInfo).length !=0, "issuerKycInfo is empty");
        if(userAccounts[msg.sender].exists == false)
        {
            bytes32 temphash = keccak256(abi.encodePacked(issuerKycInfo));
            userAccounts[msg.sender].KYChash = temphash;
            userAccounts[msg.sender].exists = true;
            userAccounts[msg.sender].createdAt = block.timestamp;
            totalUsers = totalUsers +1;
            emit CustodialAccountCreated(msg.sender, userAccounts[msg.sender].createdAt);
        }
        tokenRegistrations[symbol].tokenContractaddress = tokenAddress;
        tokenRegistrations[symbol].oracleAddress = oracleAddress;
        tokenRegistrations[symbol].issuerAddress = msg.sender;
        tokenRegistrations[symbol].custodialSupplyPerToken = 0;

        this.addCurrency(symbol, tokenAddress, oracleAddress);
        emit StablecoinRegistered(symbol, msg.sender, tokenAddress);
    }
    

    function requestDeposit(
        string memory symbol, 
        uint256 amount,
        address fromExternalWallet
    ) external accountExists(msg.sender) kycVerified(msg.sender) {
        // TODO: Implement deposit
        // This requires a real blockchain transaction (gas required)
        require(tokenRegistrations[symbol].tokenContractaddress != address(0), "token not registered");

        uint256 userwalletid = 0;
        for(uint256 i=1;i<nextWalletId;i++){
            if(userBalancePerWallet[msg.sender][i][symbol]>0){
                userwalletid = i;
                break;
            }
        }
        if (userwalletid == 0){
            for(uint256 i=1;i<nextWalletId;i++){
                if(exchangeWallets[i].isWalletActive == true){
                    userwalletid = i;
                    break;
                }
            }
        }
        address userwalletaddress = exchangeWallets[userwalletid].walletAddress;
        bool check = IERC20(tokenRegistrations[symbol].tokenContractaddress).transferFrom(fromExternalWallet, userwalletaddress,amount);
        require(check == true,"token transfer failed");

        userBalance[msg.sender][symbol] += amount;
        userBalancePerWallet[msg.sender][userwalletid][symbol] +=amount;
        exchangeWallets[userwalletid].tokenReservesperWallet[symbol] += amount;
        tokenRegistrations[symbol].custodialSupplyPerToken += amount;


        emit CustodialDeposit(msg.sender, symbol, amount, fromExternalWallet );
    }
    
  
    function requestWithdrawal(
        string memory symbol, 
        uint256 amount,
        address toExternalWallet
    ) external accountExists(msg.sender) kycVerified(msg.sender) {
        // TODO: Implement withdrawal
        // This requires a real blockchain transaction (gas required)
        require(userBalance[msg.sender][symbol] >= amount, "insufficient custodial balance");

        uint256 userwalletid = 0;
        for(uint256 i=1;i<nextWalletId;i++){
            if(userBalancePerWallet[msg.sender][i][symbol]>0){
                userwalletid = i;
                break;
            }
        }
        address userwalletaddress = exchangeWallets[userwalletid].walletAddress;

        bool check = IERC20(tokenRegistrations[symbol].tokenContractaddress).transferFrom(userwalletaddress, toExternalWallet,amount);
        require(check == true,"token transfer failed");

        userBalance[msg.sender][symbol] -= amount;
        userBalancePerWallet[msg.sender][userwalletid][symbol] -=amount;
        exchangeWallets[userwalletid].tokenReservesperWallet[symbol] -= amount;
        tokenRegistrations[symbol].custodialSupplyPerToken -= amount;

        emit CustodialWithdrawal(msg.sender, symbol, amount, toExternalWallet);
    }
 
    function custodialTransfer(
        address to, 
        string memory symbol, 
        uint256 amount
    ) external accountExists(msg.sender) kycVerified(msg.sender) 
       accountExists(to) kycVerified(to) {
        // TODO: Implement internal transfer
        // This is accounting-only (no blockchain transaction, no gas)
        
        // // user -> currency -> balance
        // mapping (address => mapping(string => uint256)) public userBalance; //custodial balance?
        // // user -> walletid -> currency -> balance
        // mapping (address => mapping(uint256 => mapping(string => uint256) )) public userBalancePerWallet;
        require(userBalance[msg.sender][symbol]>=amount,"insufficient balance");
        uint256 senderwalletid = 0;
        for(uint256 i=1;i<nextWalletId;i++){
            if(userBalancePerWallet[msg.sender][i][symbol]>=amount){
                senderwalletid = i;
                break;
            }
        }
        userBalance[msg.sender][symbol] -= amount;
        userBalancePerWallet[msg.sender][senderwalletid][symbol] -=amount;
        userBalance[to][symbol] += amount;
        userBalancePerWallet[to][senderwalletid][symbol] +=amount;

        emit CustodialTransfer(msg.sender, to, symbol, amount);
    }
    
  
    function custodialTrade(
        string memory fromSymbol, 
        string memory toSymbol, 
        uint256 amount
    ) external accountExists(msg.sender) kycVerified(msg.sender) {
        // TODO: Implement custodial trading
        // This requires real blockchain transactions (gas required)
        // 
        // Key steps:
        // 1. Get prices from parent's oracles mapping
        // 2. Calculate output amount
        // 3. Check exchange liquidity (address(this) balance)
        // 4. Move tokens: custodial wallet -> address(this) (input)
        // 5. Move tokens: address(this) -> custodial wallet (output)
        // 6. Update all balances and reserves
        require(userBalance[msg.sender][fromSymbol]>=amount,"insufficient balance");

        require(tokenRegistrations[fromSymbol].tokenContractaddress != address(0), "token not registered");
        require(tokenRegistrations[toSymbol].tokenContractaddress != address(0), "token not registered");

        uint256 outAmount = (amount * uint256(getLatestPrice(fromSymbol)) * (10**uint256(oracles[toSymbol].decimals())))/(uint256(getLatestPrice(toSymbol)) * (10**uint256(oracles[fromSymbol].decimals())));

        require(currencies[toSymbol].balanceOf(address(this))>=outAmount, "Insufficient exchange liquidity");
        userBalance[msg.sender][fromSymbol] -= amount;
        userBalance[msg.sender][toSymbol] +=outAmount;

        uint256 fromwalletid = 0;
        for(uint256 i=1;i<nextWalletId;i++){
            if(userBalancePerWallet[msg.sender][i][fromSymbol]>=amount){
                fromwalletid = i;
                break;
            }
        }
        address fromwalletaddress = exchangeWallets[fromwalletid].walletAddress;

        uint256 towalletid = 0;
        for(uint256 i=1;i<nextWalletId;i++){
            if(userBalancePerWallet[msg.sender][i][toSymbol]>0){
                towalletid = i;
                break;
            }
        }
        address towalletaddress = exchangeWallets[towalletid].walletAddress;

        bool check1 = IERC20(tokenRegistrations[fromSymbol].tokenContractaddress).transferFrom(fromwalletaddress, address(this),amount);
        require(check1 ==true, "custodial to exchange failed");
        bool check2 = IERC20(tokenRegistrations[toSymbol].tokenContractaddress).transfer(towalletaddress, outAmount);
        require(check2 ==true, "exchange to custodial failed");

        userBalancePerWallet[msg.sender][fromwalletid][fromSymbol] -= amount;
        userBalancePerWallet[msg.sender][towalletid][toSymbol] += outAmount;

        exchangeWallets[fromwalletid].tokenReservesperWallet[fromSymbol] -= amount;
        exchangeWallets[towalletid].tokenReservesperWallet[toSymbol] += outAmount;
        tokenRegistrations[fromSymbol].custodialSupplyPerToken -=amount;
        tokenRegistrations[toSymbol].custodialSupplyPerToken += outAmount;
        emit CustodialTrade(msg.sender, fromSymbol, toSymbol, amount, outAmount);
    }
    

    function getCustodialBalance(address user, string memory symbol) external view returns (uint256) {
        // TODO: Return user's total balance for this currency
        // Placeholder - replace with actual implementation
        return userBalance[user][symbol];
    }
    
  
    function getCurrencyWallet(address user, string memory symbol) external view returns (uint256) {
        // TODO: Return wallet ID for user's currency
        // Placeholder - replace with actual implementation
        for(uint256 i=1; i<nextWalletId;i++){
            if (userBalancePerWallet[user][i][symbol] > 0)
            {
                return i;
            }
        }
        for(uint256 i=1;i<nextWalletId;i++){
            if(exchangeWallets[i].tokenReservesperWallet[symbol] >0){
                return i;
            }
        }
        return 0;
    }
    
  
    function getCurrencyWalletBalance(address user, string memory symbol, uint256 walletId) external view returns (uint256) {
        // TODO: Return user's balance in specific wallet
        // Placeholder - replace with actual implementation
        return userBalancePerWallet[user][walletId][symbol];
    }
    

  
    function getAccountInfo(address user) external view returns (
        bool exists, 
        bool isKycVerified, 
        uint256 createdAt
    ) {
        // TODO: Return account information
        // Placeholder - replace with actual implementation
        return (userAccounts[user].exists, userAccounts[user].isKycVerified,userAccounts[user].createdAt);
    }
    
   
    function getKycHash(address user) external view returns (bytes32) {
        // TODO: Return stored KYC hash
        // Placeholder - replace with actual implementation
        return userAccounts[user].KYChash;
    }
   
    function getExchangeWalletReserves(uint256 walletId, string memory symbol) external view returns (uint256) {
        // TODO: Return wallet reserves
        // Placeholder - replace with actual implementation
        return exchangeWallets[walletId].tokenReservesperWallet[symbol];
    }
    

    function getExchangeWalletAddress(uint256 walletId) external view returns (address) {
        // TODO: Return wallet address
        // Placeholder - replace with actual implementation
        return exchangeWallets[walletId].walletAddress;
    }
    

    function getTotalCustodialSupply(string memory symbol) external view returns (uint256) {
        // TODO: Return total custodial supply for currency
        // Placeholder - replace with actual implementation
        return tokenRegistrations[symbol].custodialSupplyPerToken;
    }
}
