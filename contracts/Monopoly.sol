// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Monopoly is Ownable {
    // 游戏状态枚举
    enum GameState {
        NotStarted,
        InProgress,
        Paused,
        Ended
    }
    
    // 玩家结构体
    struct Player {
        address playerAddress;  //玩家位置
        uint256 balance;   //玩家余额
        uint256 position;   //玩家位置
        bool isInJail;   //是否在监狱
        uint256 jailTurns;    //监狱回合数
        bool isActive;   //是否活跃
        mapping(uint256 => uint256) properties;  //玩家房产
    }
    
    // 地产结构体
    struct Property {
        string name;   //地产名称
        uint256 price;      //地产价格
        uint256 rent;    //地产租金
        uint256 mortgageValue;      //地产抵押价值
        address owner;      //地产所有者
        bool isMortgaged;        //是否抵押
        uint256 houseCount;   //房产数量
        uint256 hotelCount;   //酒店数量
    }
    
    // 游戏状态
    GameState public currentState;      
    
    // 玩家相关
    address[] public playerAddresses;   
    mapping(address => Player) public players;      
    uint256 public playerCount;
    uint256 public maxPlayers;
    
    // 地产相关
    Property[] public properties;
    uint256 public propertyCount;
    
    // 游戏相关
    uint256 public currentPlayerIndex;
    uint256 public gameTurn;
    
    // 事件定义
    event PlayerJoined(address indexed player, uint256 playerId);   //玩家加入游戏
    event GameStarted();   //游戏开始
    event GameEnded();   //游戏结束
    event TurnStarted(address indexed player);   //回合开始
    event TurnEnded(address indexed player);   //回合结束
    event PropertyBought(address indexed buyer, uint256 propertyId);   //玩家购买地产
    event PropertySold(address indexed seller, address indexed buyer, uint256 propertyId);   //玩家卖出地产
    event RentPaid(address indexed payer, address indexed receiver, uint256 amount);   //玩家支付租金
    event PlayerMoved(address indexed player, uint256 newPosition);   //玩家移动
    event PlayerJailed(address indexed player);   //玩家入狱
    event PlayerReleased(address indexed player);   //玩家释放
    
    // 构造函数
    constructor(uint256 _maxPlayers) {
        maxPlayers = _maxPlayers;
        currentState = GameState.NotStarted;
        currentPlayerIndex = 0; // 第一个玩家开始
        gameTurn = 0; // 游戏回合数
        
        // 初始化一些基本地产（简化版）
        initializeProperties();
    }
    
    // 初始化地产
    function initializeProperties() internal {
        // 添加一些基本地产
        properties.push(Property(" Mediterranean Avenue", 60, 2, 30, address(0), false, 0, 0));  
        properties.push(Property(" Baltic Avenue", 60, 4, 30, address(0), false, 0, 0));
        properties.push(Property(" Oriental Avenue", 100, 6, 50, address(0), false, 0, 0));
        properties.push(Property(" Vermont Avenue", 100, 6, 50, address(0), false, 0, 0));
        properties.push(Property(" Connecticut Avenue", 120, 8, 60, address(0), false, 0, 0)); 
        
        propertyCount = properties.length;// 初始化地产数量
    }
    
    // 玩家加入游戏
    function joinGame() external {
        require(currentState == GameState.NotStarted, "Game has already started");
        require(!players[msg.sender].isActive, "You have already joined");
        require(playerCount < maxPlayers, "Game is full");
        
        Player storage newPlayer = players[msg.sender];
        newPlayer.playerAddress = msg.sender;
        newPlayer.balance = 1500; // 初始资金
        newPlayer.position = 0;
        newPlayer.isInJail = false;
        newPlayer.jailTurns = 0;
        newPlayer.isActive = true;
        
        playerAddresses.push(msg.sender);
        playerCount++;
        
        emit PlayerJoined(msg.sender, playerCount);
    }
    
    // 开始游戏
    function startGame() external onlyOwner {
        require(currentState == GameState.NotStarted, "Game has already started"); // 游戏已开始
        require(playerCount >= 2, "Need at least 2 players to start"); // 至少需要2名玩家
        
        currentState = GameState.InProgress; // 游戏进行中
        currentPlayerIndex = 0; // 第一个玩家开始
        gameTurn = 1;
        
        emit GameStarted();
        emit TurnStarted(playerAddresses[currentPlayerIndex]);
    }
    
    // 掷骰子
    function rollDice() external {
        require(currentState == GameState.InProgress, "Game is not in progress");
        require(msg.sender == playerAddresses[currentPlayerIndex], "Not your turn");
        
        Player storage currentPlayer = players[msg.sender];
        require(!currentPlayer.isInJail || currentPlayer.jailTurns >= 3, "You are in jail");
        
        // 模拟骰子（在实际应用中，应该使用更安全的随机数生成）
        uint256 dice1 = (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % 6) + 1;
        uint256 dice2 = (uint256(keccak256(abi.encodePacked(block.timestamp + 1, block.prevrandao))) % 6) + 1;
        uint256 totalRoll = dice1 + dice2;
        
        // 移动玩家
        movePlayer(msg.sender, totalRoll);
        
        // 结束回合
        endTurn();
    }
    
    // 移动玩家
    function movePlayer(address player, uint256 steps) internal {
        Player storage p = players[player];
        uint256 newPosition = (p.position + steps) % 40; // 假设棋盘有40个位置
        
        // 如果玩家经过起点，给予奖励
        if (newPosition < p.position) {
            p.balance += 200;
        }
        
        p.position = newPosition;
        
        // 检查是否落在地产上
        if (newPosition < propertyCount) {
            handlePropertyLanding(player, newPosition);
        }
        
        emit PlayerMoved(player, newPosition);
    }
    
    // 处理落在地产上的情况
    function handlePropertyLanding(address player, uint256 propertyId) internal {
        Property storage property = properties[propertyId];
        
        // 如果地产没有主人，可以购买
        if (property.owner == address(0)) {
            // 玩家可以选择购买（在完整实现中，应该有一个单独的购买函数）
        } 
        // 如果地产有主人且不是自己，则需要支付租金
        else if (property.owner != player) {
            Player storage playerObj = players[player];
            require(playerObj.balance >= property.rent, "Insufficient funds to pay rent");
            
            playerObj.balance -= property.rent;
            players[property.owner].balance += property.rent;
            
            emit RentPaid(player, property.owner, property.rent);
        }
    }
    
    // 购买地产
    function buyProperty(uint256 propertyId) external {
        require(currentState == GameState.InProgress, "Game is not in progress");
        require(msg.sender == playerAddresses[currentPlayerIndex], "Not your turn");
        require(propertyId < propertyCount, "Invalid property ID");
        
        Property storage property = properties[propertyId];
        require(property.owner == address(0), "Property is already owned");
        
        Player storage buyer = players[msg.sender];
        require(buyer.balance >= property.price, "Insufficient funds");
        require(buyer.position == propertyId, "You are not on this property");
        
        buyer.balance -= property.price;
        property.owner = msg.sender;
        buyer.properties[propertyId] = 1;
        
        emit PropertyBought(msg.sender, propertyId);
    }
    
    // 结束回合
    function endTurn() internal {
        emit TurnEnded(playerAddresses[currentPlayerIndex]);
        
        // 移动到下一个玩家
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount;
        
        // 检查下一个玩家是否还有资金
        while (!players[playerAddresses[currentPlayerIndex]].isActive || players[playerAddresses[currentPlayerIndex]].balance <= 0) {
            currentPlayerIndex = (currentPlayerIndex + 1) % playerCount;
        }
        
        emit TurnStarted(playerAddresses[currentPlayerIndex]);
    }
    
    // 结束游戏
    function endGame() external onlyOwner {
        require(currentState == GameState.InProgress || currentState == GameState.Paused, "Game is not active");
        
        currentState = GameState.Ended;
        emit GameEnded();
    }
    
    // 获取玩家信息（简化版）
    function getPlayerInfo(address player) external view returns (
        uint256 balance,
        uint256 position,
        bool isInJail,
        bool isActive
    ) {
        Player storage p = players[player];
        return (p.balance, p.position, p.isInJail, p.isActive);
    }
    
    // 获取当前玩家
    function getCurrentPlayer() external view returns (address) {
        return playerAddresses[currentPlayerIndex];
    }
}

//测试注释