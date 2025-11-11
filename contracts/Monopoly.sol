// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Monopoly is Ownable {
    enum GameState {
        NotStarted,
        InProgress,
        Paused,
        Ended
    }

    enum TileType {
        Property,      // 可购买地产
        Go,            // 起点（+200）
        Tax,           // 税收（固定或比例）
        Jail,          // 监狱（只是位置）
        GoToJail,      // 直接入狱
        FreeParking,   // 无事发生
        Chance,        // 机会卡（简化：暂不实现）
        CommunityChest // 公益金（简化：暂不实现）
    }

    struct Player {
        address playerAddress;
        uint256 balance;
        uint256 position;
        bool isInJail;
        uint256 jailTurns;
        bool isActive;
        mapping(uint256 => uint256) properties; // propertyId => houseCount (0=land, 1-4=houses, 5=hotel)
        uint256 getOutOfJailFreeCards; // 暂未使用，预留
    }

    struct Property {
        string name;
        uint256 price;
        uint256 baseRent;       // 无房租金
        uint256[5] houseRent;   // [1房, 2房, 3房, 4房, 酒店]
        uint256 mortgageValue;
        address owner;
        bool isMortgaged;
        uint256 colorGroup;  // 用于判断是否可建房（简化：同组地产ID连续）
        uint256 buildCost;     
    }

    struct Tile {
        TileType tileType;
        uint256 propertyId; // 仅当 tileType == Property 时有效
        uint256 taxAmount;  // 仅当 tileType == Tax 时有效
    }

    // ===== 状态变量 =====
    GameState public currentState;
    address[] public playerAddresses;
    mapping(address => Player) public players;
    uint256 public playerCount;
    uint256 public maxPlayers;

    Property[] public properties;
    Tile[40] public board; // 标准40格棋盘
    uint256 public propertyCount;

    uint256 public currentPlayerIndex;
    uint256 public gameTurn;

    // ===== 事件 =====
    event PlayerJoined(address indexed player, uint256 playerId);
    event GameStarted();
    event GameEnded();
    event TurnStarted(address indexed player);
    event TurnEnded(address indexed player);
    event PropertyBought(address indexed buyer, uint256 propertyId);
    event RentPaid(address indexed payer, address indexed receiver, uint256 amount); 
    event PlayerMoved(address indexed player, uint256 newPosition);
    event PlayerJailed(address indexed player);  //玩家入狱
    event PlayerReleased(address indexed player);
    event PropertyMortgaged(address indexed player, uint256 propertyId);  //财产抵押
    event PropertyUnmortgaged(address indexed player, uint256 propertyId);  
    event HouseBuilt(address indexed player, uint256 propertyId, uint256 houseCount);

    // ===== 构造函数 =====
    constructor(uint256 _maxPlayers) Ownable(msg.sender) {
        require(_maxPlayers >= 2 && _maxPlayers <= 8, "Invalid player count");
        maxPlayers = _maxPlayers;
        currentState = GameState.NotStarted;
        initializeBoard();
    }

        function initializeBoard() internal {
        // ===== 初始化 22 块住宅地产 =====
        // Brown (Group 0) - Build cost: 50
        properties.push(Property("Mediterranean Avenue", 60, 2, [10, 30, 90, 160, 250], 30, address(0), false, 0));
        properties.push(Property("Baltic Avenue", 60, 4, [20, 60, 180, 320, 450], 30, address(0), false, 0));

        // Light Blue (Group 1) - Build cost: 50
        properties.push(Property("Oriental Avenue", 100, 6, [30, 90, 270, 400, 550], 50, address(0), false, 1));
        properties.push(Property("Vermont Avenue", 100, 6, [30, 90, 270, 400, 550], 50, address(0), false, 1));
        properties.push(Property("Connecticut Avenue", 120, 8, [40, 100, 300, 450, 600], 60, address(0), false, 1));

        // Pink (Group 2) - Build cost: 100
        properties.push(Property("St. Charles Place", 140, 10, [50, 150, 450, 625, 750], 70, address(0), false, 2));
        properties.push(Property("States Avenue", 140, 10, [50, 150, 450, 625, 750], 70, address(0), false, 2));
        properties.push(Property("Virginia Avenue", 160, 12, [60, 180, 500, 700, 900], 80, address(0), false, 2));

        // Orange (Group 3) - Build cost: 100
        properties.push(Property("St. James Place", 180, 14, [70, 200, 550, 750, 950], 90, address(0), false, 3));
        properties.push(Property("Tennessee Avenue", 180, 14, [70, 200, 550, 750, 950], 90, address(0), false, 3));
        properties.push(Property("New York Avenue", 200, 16, [80, 220, 600, 800, 1000], 100, address(0), false, 3));

        // Red (Group 4) - Build cost: 150
        properties.push(Property("Kentucky Avenue", 220, 18, [90, 250, 700, 875, 1050], 110, address(0), false, 4));
        properties.push(Property("Indiana Avenue", 220, 18, [90, 250, 700, 875, 1050], 110, address(0), false, 4));
        properties.push(Property("Illinois Avenue", 240, 20, [100, 300, 750, 925, 1100], 120, address(0), false, 4));

        // Yellow (Group 5) - Build cost: 150
        properties.push(Property("Atlantic Avenue", 260, 22, [110, 330, 800, 975, 1150], 130, address(0), false, 5));
        properties.push(Property("Ventnor Avenue", 260, 22, [110, 330, 800, 975, 1150], 130, address(0), false, 5));
        properties.push(Property("Marvin Gardens", 280, 24, [120, 360, 850, 1025, 1200], 140, address(0), false, 5));

        // Green (Group 6) - Build cost: 200
        properties.push(Property("Pacific Avenue", 300, 26, [130, 390, 900, 1100, 1275], 150, address(0), false, 6));
        properties.push(Property("North Carolina Avenue", 300, 26, [130, 390, 900, 1100, 1275], 150, address(0), false, 6));
        properties.push(Property("Pennsylvania Avenue", 320, 28, [150, 450, 1000, 1200, 1400], 160, address(0), false, 6));

        // Dark Blue (Group 7) - Build cost: 200
        properties.push(Property("Park Place", 350, 35, [175, 500, 1100, 1300, 1500], 175, address(0), false, 7));
        properties.push(Property("Boardwalk", 400, 50, [200, 600, 1400, 1700, 2000], 200, address(0), false, 7));

        propertyCount = properties.length; // = 22

        // ===== 初始化 40 格棋盘 =====
        for (uint256 i = 0; i < 40; i++) {
            board[i] = Tile(TileType.FreeParking, 0, 0); // 默认占位
        }

        // 固定功能格子
        board[0]  = Tile(TileType.Go, 0, 0);
        board[2]  = Tile(TileType.CommunityChest, 0, 0);
        board[4]  = Tile(TileType.Tax, 0, 200);      // Income Tax
        board[7]  = Tile(TileType.Chance, 0, 0);
        board[10] = Tile(TileType.Jail, 0, 0);
        board[17] = Tile(TileType.CommunityChest, 0, 0);
        board[20] = Tile(TileType.FreeParking, 0, 0);
        board[22] = Tile(TileType.Chance, 0, 0);
        board[30] = Tile(TileType.GoToJail, 0, 0);
        board[33] = Tile(TileType.CommunityChest, 0, 0);
        board[36] = Tile(TileType.Chance, 0, 0);
        board[38] = Tile(TileType.Tax, 0, 100);      // Luxury Tax

        // 住宅地产位置（标准美版布局）
        board[1]  = Tile(TileType.Property, 0, 0);   // Mediterranean Ave
        board[3]  = Tile(TileType.Property, 1, 0);   // Baltic Ave
        board[6]  = Tile(TileType.Property, 2, 0);   // Oriental Ave
        board[8]  = Tile(TileType.Property, 3, 0);   // Vermont Ave
        board[9]  = Tile(TileType.Property, 4, 0);   // Connecticut Ave
        board[11] = Tile(TileType.Property, 5, 0);   // St. Charles Place
        board[13] = Tile(TileType.Property, 6, 0);   // States Ave
        board[14] = Tile(TileType.Property, 7, 0);   // Virginia Ave
        board[16] = Tile(TileType.Property, 8, 0);   // St. James Place
        board[18] = Tile(TileType.Property, 9, 0);   // Tennessee Ave
        board[19] = Tile(TileType.Property, 10, 0);  // New York Ave
        board[21] = Tile(TileType.Property, 11, 0);  // Kentucky Ave
        board[23] = Tile(TileType.Property, 12, 0);  // Indiana Ave
        board[24] = Tile(TileType.Property, 13, 0);  // Illinois Ave
        board[26] = Tile(TileType.Property, 14, 0);  // Atlantic Ave
        board[27] = Tile(TileType.Property, 15, 0);  // Ventnor Ave
        board[29] = Tile(TileType.Property, 16, 0);  // Marvin Gardens
        board[31] = Tile(TileType.Property, 17, 0);  // Pacific Ave
        board[32] = Tile(TileType.Property, 18, 0);  // North Carolina Ave
        board[34] = Tile(TileType.Property, 19, 0);  // Pennsylvania Ave
        board[37] = Tile(TileType.Property, 20, 0);  // Park Place
        board[39] = Tile(TileType.Property, 21, 0);  // Boardwalk

        // 注意：铁路（5,15,25,35）和公共事业（12,28）未包含在 Property 中
        // 如果你需要支持它们，需扩展 TileType 或 Property 结构
    }

    // ===== 游戏控制 =====
    function joinGame() external {
        require(currentState == GameState.NotStarted, "Game has already started");
        require(!players[msg.sender].isActive, "Already joined");
        require(playerCount < maxPlayers, "Game full");

        Player storage p = players[msg.sender];
        p.playerAddress = msg.sender;
        p.balance = 1500;
        p.position = 0;
        p.isInJail = false;
        p.jailTurns = 0;
        p.isActive = true;

        playerAddresses.push(msg.sender);
        playerCount++;
        emit PlayerJoined(msg.sender, playerCount);
    }

    function startGame() external onlyOwner {
        require(currentState == GameState.NotStarted, "Already started");
        require(playerCount >= 2, "Need >=2 players");
        currentState = GameState.InProgress;
        currentPlayerIndex = 0;
        gameTurn = 1;
        emit GameStarted();
        emit TurnStarted(playerAddresses[0]);
    }

    function endGame() external onlyOwner {
        require(currentState == GameState.InProgress || currentState == GameState.Paused, "Not active");
        currentState = GameState.Ended;
        emit GameEnded();
    }

    // ===== 回合操作 =====
    function rollDice() external {
        _requireMyTurn();
        Player storage p = players[msg.sender];

        if (p.isInJail) {
            require(p.jailTurns < 3, "Must pay or use card to leave after 3 turns");
            p.jailTurns++;
            if (p.jailTurns >= 3) {
                _releaseFromJail(msg.sender);
            }
            emit TurnEnded(msg.sender);
            _nextTurn();
            return;
        }

        uint256 dice1 = (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 6) + 1;
        uint256 dice2 = (uint256(keccak256(abi.encodePacked(block.timestamp + 1, block.prevrandao, msg.sender))) % 6) + 1;
        uint256 total = dice1 + dice2;

        _movePlayer(msg.sender, total);

        // 如果是双骰，可再掷一次（简化：暂不实现）
        emit TurnEnded(msg.sender);
        _nextTurn();
    }

    function payToLeaveJail() external {
        _requireMyTurn();
        Player storage p = players[msg.sender];
        require(p.isInJail, "Not in jail");
        require(p.balance >= 50, "Insufficient balance");

        p.balance -= 50;
        _releaseFromJail(msg.sender);
        emit TurnEnded(msg.sender);
        _nextTurn();
    }

    // ===== 地产操作 =====
    function buyProperty(uint256 propertyId) external {
        _requireMyTurn();
        require(propertyId < propertyCount, "Invalid ID");
        Property storage prop = properties[propertyId];
        require(prop.owner == address(0), "Already owned");
        require(players[msg.sender].position == propertyId, "Not on this tile");
        require(players[msg.sender].balance >= prop.price, "Insufficient funds");

        players[msg.sender].balance -= prop.price;
        prop.owner = msg.sender;
        emit PropertyBought(msg.sender, propertyId);
    }

    function mortgageProperty(uint256 propertyId) external {
        require(currentState == GameState.InProgress, "Game not in progress");
        Property storage prop = properties[propertyId];
        require(prop.owner == msg.sender, "Not your property");
        require(!prop.isMortgaged, "Already mortgaged");

        prop.isMortgaged = true;
        players[msg.sender].balance += prop.mortgageValue;
        emit PropertyMortgaged(msg.sender, propertyId);
    }

    function unmortgageProperty(uint256 propertyId) external {
        require(currentState == GameState.InProgress, "Game not in progress");
        Property storage prop = properties[propertyId];
        require(prop.owner == msg.sender, "Not your property");
        require(prop.isMortgaged, "Not mortgaged");

        uint256 cost = (prop.mortgageValue * 11) / 10; // 10% 利息
        require(players[msg.sender].balance >= cost, "Insufficient funds");

        players[msg.sender].balance -= cost;
        prop.isMortgaged = false;
        emit PropertyUnmortgaged(msg.sender, propertyId);
    }

    function getBuildCost(uint256 group) internal pure returns (uint256) {
    if (group == 0 || group == 1) return 50;
    if (group == 2 || group == 3) return 100;
    if (group == 4 || group == 5) return 150;
    if (group == 6 || group == 7) return 200;
    return 0; // should not happen
}

    function buildHouse(uint256 propertyId) external {
    require(currentState == GameState.InProgress, "Game not in progress");
    Property storage prop = properties[propertyId];
    require(prop.owner == msg.sender, "Not your property");
    require(!prop.isMortgaged, "Property mortgaged");
    require(
        players[msg.sender].position == propertyId || 
        _ownsFullColorGroup(msg.sender, prop.colorGroup),
        "Must own full color group to build"
    );

    uint256 currentHouses = players[msg.sender].properties[propertyId];
    require(currentHouses < 5, "Max houses/hotel reached");

    // ✅ 使用该地产的实际建房成本
    uint256 buildCost = getBuildCost(prop.colorGroup);
    require(players[msg.sender].balance >= buildCost, "Insufficient funds to build");

    players[msg.sender].balance -= buildCost;
    players[msg.sender].properties[propertyId] += 1;

    emit HouseBuilt(msg.sender, propertyId, players[msg.sender].properties[propertyId]);
}

    // ===== 内部函数 =====
    function _movePlayer(address player, uint256 steps) internal {
        Player storage p = players[player];
        uint256 oldPos = p.position;
        uint256 newPos = (oldPos + steps) % 40;

        if (newPos < oldPos) {
            p.balance += 200; // 经过 Go
        }

        p.position = newPos;

        Tile memory tile = board[newPos];
        if (tile.tileType == TileType.GoToJail) {
            _sendToJail(player);
        } else if (tile.tileType == TileType.Tax) {
            require(p.balance >= tile.taxAmount, "Cannot pay tax");
            p.balance -= tile.taxAmount;
        } else if (tile.tileType == TileType.Property) {
            _handlePropertyLanding(player, tile.propertyId);
        }

        emit PlayerMoved(player, newPos);
    }

    function _handlePropertyLanding(address player, uint256 propertyId) internal {
        Property storage prop = properties[propertyId];
        if (prop.owner == address(0)) {
            // 前端应提示“是否购买”
            return;
        }
        if (prop.owner == player || prop.isMortgaged) {
            return;
        }

        uint256 rent = prop.baseRent;
        uint256 houses = players[prop.owner].properties[propertyId];
        if (houses > 0) {
            rent = prop.houseRent[houses - 1];
        }

        Player storage payer = players[player];
        require(payer.balance >= rent, "Insufficient funds");
        payer.balance -= rent;
        players[prop.owner].balance += rent;
        emit RentPaid(player, prop.owner, rent);
    }

    function _sendToJail(address player) internal {
        players[player].isInJail = true;
        players[player].jailTurns = 0;
        players[player].position = 10; // Jail position
        emit PlayerJailed(player);
    }

    function _releaseFromJail(address player) internal {
        players[player].isInJail = false;
        players[player].jailTurns = 0;
        emit PlayerReleased(player);
    }

    function _ownsFullColorGroup(address player, uint256 group) internal view returns (bool) {
    uint256 count = 0;
    for (uint256 i = 0; i < propertyCount; i++) {
        if (properties[i].colorGroup == group && properties[i].owner == player) {
            count++;
        }
    }

    // 各组所需数量
    if (group == 0 || group == 7) return count == 2; // Brown & Dark Blue
    else return count == 3; // 其他6组都是3块
}

    function _requireMyTurn() internal view {
        require(currentState == GameState.InProgress, "Game not in progress");
        require(msg.sender == playerAddresses[currentPlayerIndex], "Not your turn");
        require(players[msg.sender].isActive && players[msg.sender].balance > 0, "Player bankrupt");
    }

    function _nextTurn() internal {
        uint256 startIndex = currentPlayerIndex;
        do {
            currentPlayerIndex = (currentPlayerIndex + 1) % playerCount;
            address next = playerAddresses[currentPlayerIndex];
            if (players[next].isActive && players[next].balance > 0) {
                emit TurnStarted(next);
                return;
            }
        } while (currentPlayerIndex != startIndex);
        // 所有玩家破产？结束游戏
        endGame();
    }

    // ===== 查询函数 =====
    function getPlayerInfo(address player) external view returns (
        uint256 balance,
        uint256 position,
        bool isInJail,
        bool isActive
    ) {
        Player storage p = players[player];
        return (p.balance, p.position, p.isInJail, p.isActive);
    }

    function getCurrentPlayer() external view returns (address) {
        return playerAddresses[currentPlayerIndex];
    }
<<<<<<< Updated upstream
}

//测试注释
=======

    function getTile(uint256 index) external view returns (Tile memory) {
        require(index < 40, "Invalid tile");
        return board[index];
    }
}
>>>>>>> Stashed changes
