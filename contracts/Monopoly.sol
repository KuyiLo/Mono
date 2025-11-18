// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

enum CardEffect{
        CollectMoney,
        PayMoney,
        GoToJail,
        AdvanceToGo,
        AdvanceToTile
    }

struct Card {
    CardEffect effect;
    uint256 param;
    }

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

    enum PropertyCategory{
        Regular,     // 普通住宅
        Railroad,    // 铁路
        Utility      // 公共事业（水电）
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
        PropertyCategory category;    
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

    Card[] public  chanceCards;
    Card[] public communityChestCards;
    uint256 public nonce;


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
    event DiceRolled(address indexed player, uint256 dice1, uint256 dice2, uint256 total);//掷骰子
    event MoneyReceived(address indexed player, uint256 amount);
    event CardDrawn(address indexed player, CardEffect effect, uint256 param);



    // ===== 构造函数 =====
    constructor(uint256 _maxPlayers) Ownable(msg.sender) {
        require(_maxPlayers >= 2 && _maxPlayers <= 8, "Invalid player count");
        maxPlayers = _maxPlayers;
        currentState = GameState.NotStarted;
        initializeBoard();

         // --- Chance Cards (机会卡) ---
        chanceCards.push(Card(CardEffect.CollectMoney, 50));   // 银行分红
        chanceCards.push(Card(CardEffect.AdvanceToGo, 0));     // 前往起点
        chanceCards.push(Card(CardEffect.GoToJail, 0));        // 直接入狱
        chanceCards.push(Card(CardEffect.AdvanceToTile, 39));  // Boardwalk
        chanceCards.push(Card(CardEffect.PayMoney, 15));       // 学校税 $15


        // --- Community Chest Cards (公益福利卡) ---
        communityChestCards.push(Card(CardEffect.CollectMoney, 100)); // 生日礼物
        communityChestCards.push(Card(CardEffect.AdvanceToGo, 0));    // 前往起点
        communityChestCards.push(Card(CardEffect.CollectMoney, 20));  // 小额奖金
        communityChestCards.push(Card(CardEffect.PayMoney, 10));      // 医疗费用 $10
        communityChestCards.push(Card(CardEffect.GoToJail, 0));       // 法律纠纷入狱
    }

        function initializeBoard() internal {
        // ===== 初始化 22 块住宅地产 =====
        // Brown (Group 0) - Build cost: 50
        properties.push(Property("Mediterranean Avenue", 60, 2,  [uint256(10), uint256(30), uint256(90), uint256(160), uint256(250)], 30, address(0), false, 0,50, PropertyCategory.Regular));
        properties.push(Property("Baltic Avenue", 60, 4, [uint256(20), uint256(60), uint256(180), uint256(320), uint256(450)], 30, address(0), false, 0,50, PropertyCategory.Regular));

        // Light Blue (Group 1) - Build cost: 50
        properties.push(Property("Oriental Avenue", 100, 6, [uint256(30), uint(90), uint256(270),uint256(400), uint256(550)], 50, address(0), false, 1,50, PropertyCategory.Regular));
        properties.push(Property("Vermont Avenue", 100, 6, [uint256(30), uint256(90), uint256(270), uint256(400), uint256(550)], 50, address(0), false, 1,50, PropertyCategory.Regular));
        properties.push(Property("Connecticut Avenue", 120, 8, [uint256(40), uint256(100), uint256(300), uint256(450), uint256(600)], 60, address(0), false, 1,50, PropertyCategory.Regular));

        // Pink (Group 2) - Build cost: 100
        properties.push(Property("St. Charles Place", 140, 10, [uint256(50), uint256(150), uint256(450), uint256(625), uint256(750)], 70, address(0), false, 2,100, PropertyCategory.Regular));
        properties.push(Property("States Avenue", 140, 10, [uint256(50), uint256(150), uint256(450), uint256(625), uint256(750)], 70, address(0), false, 2,100, PropertyCategory.Regular));
        properties.push(Property("Virginia Avenue", 160, 12, [uint256(60), uint256(180), uint256(500), uint256(700), uint256(900)], 80, address(0), false, 2,100, PropertyCategory.Regular));

        // Orange (Group 3) - Build cost: 100
        properties.push(Property("St. James Place", 180, 14, [uint256(70), uint256(200), uint256(550), uint256(750), uint256(950)], 90, address(0), false, 3,100, PropertyCategory.Regular));
        properties.push(Property("Tennessee Avenue", 180, 14, [uint256(70), uint256(200), uint256(550), uint256(750), uint256(950)], 90, address(0), false, 3,100, PropertyCategory.Regular));
        properties.push(Property("New York Avenue", 200, 16, [uint256(80), uint256(220), uint256(600), uint256(800), uint256(1000)], 100, address(0), false, 3,100, PropertyCategory.Regular));

        // Red (Group 4) - Build cost: 150
        properties.push(Property("Kentucky Avenue", 220, 18, [uint256(90), uint256(250), uint256(700), uint256(875), uint256(1050)], 110, address(0), false, 4,150, PropertyCategory.Regular));
        properties.push(Property("Indiana Avenue", 220, 18, [uint256(90), uint256(250), uint256(700), uint256(875), uint256(1050)], 110, address(0), false, 4,150, PropertyCategory.Regular));
        properties.push(Property("Illinois Avenue", 240, 20, [uint256(100), uint256(300), uint256(750), uint256(925), uint256(1100)], 120, address(0), false, 4,150, PropertyCategory.Regular));

        // Yellow (Group 5) - Build cost: 150
        properties.push(Property("Atlantic Avenue", 260, 22, [uint256(110), uint256(330), uint256(800), uint256(975), uint256(1150)], 130, address(0), false, 5,150, PropertyCategory.Regular));
        properties.push(Property("Ventnor Avenue", 260, 22, [uint256(110), uint256(330), uint256(800), uint256(975), uint256(1150)], 130, address(0), false, 5,150, PropertyCategory.Regular));
        properties.push(Property("Marvin Gardens", 280, 24, [uint256(120), uint256(360), uint256(850), uint256(1025), uint256(1200)], 140, address(0), false, 5,150, PropertyCategory.Regular));

        // Green (Group 6) - Build cost: 200
        properties.push(Property("Pacific Avenue", 300, 26, [uint256(130), uint256(390), uint256(900), uint256(1100), uint256(1275)], 150, address(0), false, 6,200, PropertyCategory.Regular));
        properties.push(Property("North Carolina Avenue", 300, 26, [uint256(130), uint256(390), uint256(900), uint256(1100), uint(1275)], 150, address(0), false, 6,200, PropertyCategory.Regular));
        properties.push(Property("Pennsylvania Avenue", 320, 28, [uint256(150), uint256(450), uint256(1000), uint256(1200), uint256(1400)], 160, address(0), false, 6,200, PropertyCategory.Regular));

        // Dark Blue (Group 7) - Build cost: 200
        properties.push(Property("Park Place", 350, 35, [uint256(175), uint256(500), uint256(1100), uint256(1300), uint256(1500)], 175, address(0), false, 7,200, PropertyCategory.Regular));
        properties.push(Property("Boardwalk", 400, 50, [uint256(200), uint256(600), uint256(1400), uint256(1700), uint256(2000)], 200, address(0), false, 7,200, PropertyCategory.Regular));

        // Railroads (Group 8, category=Railroad)
        properties.push(Property("Reading Railroad", 200, 25, [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)], 100, address(0), false, 8, 0, PropertyCategory.Railroad));
        properties.push(Property("Pennsylvania Railroad", 200, 25, [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)], 100, address(0), false, 8, 0, PropertyCategory.Railroad));
        properties.push(Property("B. & O. Railroad", 200, 25, [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)], 100, address(0), false, 8, 0, PropertyCategory.Railroad));
        properties.push(Property("Short Line", 200, 25, [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)], 100, address(0), false, 8, 0, PropertyCategory.Railroad));

        // Utilities (Group 9, category=Utility)
        properties.push(Property("Electric Company", 150, 4, [uint256(0),uint256(0),uint(0),uint256(0),uint256(0)], 75, address(0), false, 9, 0, PropertyCategory.Utility));
        properties.push(Property("Water Works", 150, 4, [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)], 75, address(0), false, 9, 0, PropertyCategory.Utility));

        propertyCount = properties.length; // = 28

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

        // 住宅地产位置
        board[1]  = Tile(TileType.Property, 0, 0);   // Mediterranean Ave
        board[3]  = Tile(TileType.Property, 1, 0);   // Baltic Ave
        board[5]  = Tile(TileType.Property, 22, 0);  // Reading RR
        board[6]  = Tile(TileType.Property, 2, 0);   // Oriental Ave
        board[8]  = Tile(TileType.Property, 3, 0);   // Vermont Ave
        board[9]  = Tile(TileType.Property, 4, 0);   // Connecticut Ave
        board[11] = Tile(TileType.Property, 5, 0);   // St. Charles Place
        board[12] = Tile(TileType.Property, 26, 0);  // Electric Co.
        board[13] = Tile(TileType.Property, 6, 0);   // States Ave
        board[14] = Tile(TileType.Property, 7, 0);   // Virginia Ave
        board[15] = Tile(TileType.Property,23, 0);
        board[16] = Tile(TileType.Property, 8, 0);   // St. James Place
        board[18] = Tile(TileType.Property, 9, 0);   // Tennessee Ave
        board[19] = Tile(TileType.Property, 10, 0);  // New York Ave
        board[21] = Tile(TileType.Property, 11, 0);  // Kentucky Ave
        board[23] = Tile(TileType.Property, 12, 0);  // Indiana Ave
        board[24] = Tile(TileType.Property, 13, 0);  // Illinois Ave
        board[25] = Tile(TileType.Property, 24, 0);  // B.&O. RR
        board[26] = Tile(TileType.Property, 14, 0);  // Atlantic Ave
        board[27] = Tile(TileType.Property, 15, 0);  // Ventnor Ave
        board[28] = Tile(TileType.Property, 27, 0);  // Water Works
        board[29] = Tile(TileType.Property, 16, 0);  // Marvin Gardens
        board[31] = Tile(TileType.Property, 17, 0);  // Pacific Ave
        board[32] = Tile(TileType.Property, 18, 0);  // North Carolina Ave
        board[34] = Tile(TileType.Property, 19, 0);  // Pennsylvania Ave
        board[35] = Tile(TileType.Property, 25, 0);  // Short Line
        board[37] = Tile(TileType.Property, 20, 0);  // Park Place
        board[39] = Tile(TileType.Property, 21, 0);  // Boardwalk
    }


    function drawChanceCard() external {
    _requireMyTurn();
    _drawCard(chanceCards);
    emit TurnEnded(msg.sender);
    _nextTurn();
    }

    function drawCommunityChestCard() external {
    _requireMyTurn();
    _drawCard(communityChestCards);
    emit TurnEnded(msg.sender);
    _nextTurn();
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

        //bool isDouble = (dice1 == dice2);

        _movePlayer(msg.sender, total, total);

        emit DiceRolled(msg.sender, dice1, dice2, total);

        // 如果是双骰，可再掷一次
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

    //  使用该地产的实际建房成本
    uint256 buildCost = getBuildCost(prop.colorGroup);
    require(players[msg.sender].balance >= buildCost, "Insufficient funds to build");

    players[msg.sender].balance -= buildCost;
    players[msg.sender].properties[propertyId] += 1;

    emit HouseBuilt(msg.sender, propertyId, players[msg.sender].properties[propertyId]);
}

    // ===== 内部函数 =====
    function _movePlayer(address player, uint256 steps, uint256 diceTotal) internal {
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
            _handlePropertyLanding(player, tile.propertyId,diceTotal);
        }

        if (tile.tileType == TileType.Property) {
            _handlePropertyLanding(player, tile.propertyId, diceTotal); 
        }

        emit PlayerMoved(player, newPos);
    }

    function _checkGameEnd() internal {
    uint256 activePlayers = 0;
    address lastPlayer;
    for (uint256 i = 0; i < playerCount; i++) {
        if (players[playerAddresses[i]].isActive) {
            activePlayers++;
            lastPlayer = playerAddresses[i];
        }
    }
    if (activePlayers <= 1) {
        currentState = GameState.Ended;
        emit GameEnded();
        // 可选：emit Winner(lastPlayer);
    }
}

    // 支付或破产
function _payOrBankrupt(address payer, address receiver, uint256 amount) internal {
    if (amount == 0) return;
    Player storage p = players[payer];
    if (p.balance >= amount) {
        p.balance -= amount;
        players[receiver].balance += amount;
        emit RentPaid(payer, receiver, amount);
    } else {
        // 无法支付 → 破产
        p.balance = 0;
        players[receiver].balance += p.balance; // 实际为0
        emit RentPaid(payer, receiver, p.balance);
        // 触发破产
        _triggerBankruptcy(payer, receiver);
    }
}

function _triggerBankruptcy(address bankruptPlayer, address creditor) internal {
    // 但为避免重入，我们直接内联逻辑
    Player storage p = players[bankruptPlayer];
    if (!p.isActive) return;
    
    address receiver = (creditor != address(0) && players[creditor].isActive) ? creditor : address(0);
    for (uint256 i = 0; i < propertyCount; i++) {
        if (properties[i].owner == bankruptPlayer) {
            properties[i].owner = receiver;
            delete players[bankruptPlayer].properties[i];
        }
    }
    p.isActive = false;
    p.balance = 0;
    _checkGameEnd();
}

    function _handlePropertyLanding(
    address player,
    uint256 propertyId,
    uint256 diceTotal   
) internal {
    Property storage prop = properties[propertyId];
    
    // 如果是空地、自己拥有、或已抵押，不收租
    if (prop.owner == address(0) || prop.owner == player || prop.isMortgaged) {
        return;
    }

    uint256 rent = 0;

    if (prop.category == PropertyCategory.Regular) {
        uint256 houses = players[prop.owner].properties[propertyId];
        rent = houses > 0 ? prop.houseRent[houses - 1] : prop.baseRent;
    }
    else if (prop.category == PropertyCategory.Railroad) {
        uint256 ownedRailroads = 0;
        for (uint256 i = 22; i <= 25; i++) {
            if (properties[i].owner == prop.owner && !properties[i].isMortgaged) {
                ownedRailroads++;
            }
        }
        rent = prop.baseRent * ownedRailroads;
    }
    else if (prop.category == PropertyCategory.Utility) {
        uint256 ownedUtilities = 0;
        for (uint256 i = 26; i <= 27; i++) {
            if (properties[i].owner == prop.owner && !properties[i].isMortgaged) {
                ownedUtilities++;
            }
        }
        rent = diceTotal * (ownedUtilities == 2 ? 10 : 4); // ✅ 现在 diceTotal 已定义
    }

    _payOrBankrupt(player, prop.owner, rent);
}

    

    function declareBankruptcy(address creditor) external {
    require(currentState == GameState.InProgress, "Game not in progress");
    Player storage p = players[msg.sender];
    require(p.isActive, "Already bankrupt");

    // 转移所有未抵押地产给债权人（若无人则归银行/address(0)）
    address receiver = (creditor != address(0) && players[creditor].isActive) ? creditor : address(0);
    
    for (uint256 i = 0; i < propertyCount; i++) {
        if (properties[i].owner == msg.sender) {
            properties[i].owner = receiver;
            // 房屋/酒店不转移（简化：直接清除）
            delete players[msg.sender].properties[i];
        }
    }

    p.isActive = false;
    p.balance = 0;

    // 检查是否游戏结束
    _checkGameEnd();
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
        this.endGame();
    }
    
     function _drawCard(Card[] storage deck) internal {
        require(deck.length > 0, "Empty card deck");

        // 使用 nonce 增强随机性（防止重放攻击影响结果）
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % deck.length;
        nonce++; // 自增 nonce

        Card memory card = deck[randomIndex];
        address player = msg.sender;

        if (card.effect == CardEffect.CollectMoney) {
            players[player].balance += card.param;
            emit MoneyReceived(player, card.param);
        }
        else if (card.effect == CardEffect.PayMoney) {
            _payOrBankrupt(player, address(0), card.param); // 支付给银行（address(0)）
        }
        else if (card.effect == CardEffect.GoToJail) {
            _sendToJail(player);
        }
        else if (card.effect == CardEffect.AdvanceToGo) {
            players[player].position = 0;
            players[player].balance += 200; // 经过 Go 获得 $200
            emit PlayerMoved(player, 0);
        }
        else if (card.effect == CardEffect.AdvanceToTile) {
            uint256 target = card.param;
            require(target < board.length, "Invalid tile position");
            players[player].position = target;
            emit PlayerMoved(player, target);
        }

        emit CardDrawn(player, card.effect, card.param);
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
}