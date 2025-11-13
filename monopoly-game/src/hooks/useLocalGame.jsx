import React, { createContext, useContext, useState, useCallback } from 'react'
import { useLocalWallet } from './useLocalWallet'
import { boardData, getRent } from '../utils/boardData'

const LocalGameContext = createContext()

// 初始游戏状态
const initialGameState = {
  state: 0, // 0: 未开始, 1: 进行中, 2: 暂停, 3: 结束
  currentPlayerIndex: 0,
  players: [],
  properties: [],
  board: boardData.map(tile => ({
    ...tile,
    owner: null,
    houses: 0,
    isMortgaged: false
  }))
}

export const LocalGameProvider = ({ children }) => {
  const { currentWallet, updateBalance, wallets } = useLocalWallet()
  const [gameState, setGameState] = useState(initialGameState)
  const [players, setPlayers] = useState([])
  const [message, setMessage] = useState('')

  // 显示消息
  const showMessage = (text, duration = 3000) => {
    setMessage(text)
    setTimeout(() => setMessage(''), duration)
  }

  // 加入游戏
  const joinGame = useCallback(() => {
    if (!currentWallet) {
      showMessage('请先连接钱包')
      return false
    }

    setPlayers(prev => {
      if (prev.find(p => p.address === currentWallet.address)) {
        showMessage('你已经加入游戏了')
        return prev
      }
      
      const newPlayer = {
        address: currentWallet.address,
        nickname: currentWallet.nickname,
        balance: currentWallet.balance,
        position: 0,
        isInJail: false,
        jailTurns: 0,
        properties: [],
        isActive: true,
        getOutOfJailCards: 0
      }
      
      showMessage(`${currentWallet.nickname} 加入了游戏！`)
      return [...prev, newPlayer]
    })

    return true
  }, [currentWallet])

  // 开始游戏
  const startGame = useCallback(() => {
    if (players.length < 2) {
      showMessage('需要至少2名玩家才能开始游戏')
      return false
    }

    setGameState(prev => ({
      ...prev,
      state: 1,
      currentPlayerIndex: 0
    }))

    showMessage('游戏开始！第一个回合：' + players[0].nickname)
    return true
  }, [players])

  // 掷骰子
  const rollDice = useCallback(() => {
    if (gameState.state !== 1) {
      showMessage('游戏尚未开始')
      return
    }

    if (!currentWallet) {
      showMessage('请先连接钱包')
      return
    }

    const currentPlayer = players[gameState.currentPlayerIndex]
    if (currentPlayer.address !== currentWallet.address) {
      showMessage(`现在不是你的回合，当前是 ${currentPlayer.nickname} 的回合`)
      return
    }

    // 模拟掷骰子
    const dice1 = Math.floor(Math.random() * 6) + 1
    const dice2 = Math.floor(Math.random() * 6) + 1
    const total = dice1 + dice2
    const isDouble = dice1 === dice2

    showMessage(`${currentPlayer.nickname} 掷出: ${dice1} + ${dice2} = ${total}`)

    // 移动玩家
    setPlayers(prev => prev.map(player => {
      if (player.address === currentWallet.address) {
        const newPosition = (player.position + total) % 40
        let newBalance = player.balance
        
        // 如果经过起点
        if (newPosition < player.position) {
          newBalance += 200
          showMessage(`${player.nickname} 经过起点，获得200！`)
        }

        const newTile = gameState.board[newPosition]
        
        // 处理不同格子的效果
        switch (newTile.type) {
          case 'tax':
            const taxAmount = newTile.name === '所得税' ? 200 : 100
            newBalance -= taxAmount
            showMessage(`${player.nickname} 支付${taxAmount}税费`)
            break
            
          case 'go-to-jail':
            showMessage(`${player.nickname} 直接入狱！`)
            return {
              ...player,
              position: 10, // 监狱位置
              isInJail: true,
              balance: newBalance
            }
            
          case 'property':
          case 'railroad':
          case 'utility':
            if (newTile.owner && newTile.owner !== player.address) {
              const owner = players.find(p => p.address === newTile.owner)
              const rent = getRent(newTile, newTile.houses)
              newBalance -= rent
              
              // 更新所有者余额
              setPlayers(prevPlayers => prevPlayers.map(p => 
                p.address === newTile.owner 
                  ? { ...p, balance: p.balance + rent }
                  : p
              ))
              
              showMessage(`${player.nickname} 支付租金 ${rent} 给 ${owner.nickname}`)
            }
            break
        }

        return {
          ...player,
          position: newPosition,
          balance: newBalance
        }
      }
      return player
    }))

    // 更新玩家余额
    updateBalance(currentWallet.address, 
      players.find(p => p.address === currentWallet.address).balance
    )

    // 更新下一个玩家（如果不是双骰）
    if (!isDouble) {
      setGameState(prev => ({
        ...prev,
        currentPlayerIndex: (prev.currentPlayerIndex + 1) % players.length
      }))
      
      const nextPlayer = players[(gameState.currentPlayerIndex + 1) % players.length]
      showMessage(`下一个回合：${nextPlayer.nickname}`)
    } else {
      showMessage('掷出双骰！再掷一次')
    }
  }, [gameState, currentWallet, players, updateBalance])

  // 购买地产
  const buyProperty = useCallback(() => {
    if (!currentWallet) {
      showMessage('请先连接钱包')
      return
    }

    const currentPlayer = players.find(p => p.address === currentWallet.address)
    if (!currentPlayer) {
      showMessage('你尚未加入游戏')
      return
    }

    const currentTile = gameState.board[currentPlayer.position]
    
    if (!['property', 'railroad', 'utility'].includes(currentTile.type)) {
      showMessage('当前位置无法购买地产')
      return
    }

    if (currentTile.owner) {
      showMessage('该地产已有主人')
      return
    }

    if (currentPlayer.balance < currentTile.price) {
      showMessage('余额不足')
      return
    }

    // 购买地产
    setGameState(prev => ({
      ...prev,
      board: prev.board.map(tile => 
        tile.position === currentPlayer.position 
          ? { ...tile, owner: currentWallet.address }
          : tile
      )
    }))

    // 更新玩家余额和财产
    const newBalance = currentPlayer.balance - currentTile.price
    setPlayers(prev => prev.map(player => {
      if (player.address === currentWallet.address) {
        return {
          ...player,
          balance: newBalance,
          properties: [...player.properties, currentPlayer.position]
        }
      }
      return player
    }))

    updateBalance(currentWallet.address, newBalance)
    showMessage(`成功购买 ${currentTile.name}！花费 ${currentTile.price}`)
  }, [currentWallet, players, gameState.board, updateBalance])

  // 建造房屋
  const buildHouse = useCallback((position) => {
    if (!currentWallet) {
      showMessage('请先连接钱包')
      return
    }

    const tile = gameState.board[position]
    if (!tile.owner || tile.owner !== currentWallet.address) {
      showMessage('你不是这个地产的主人')
      return
    }

    if (tile.houses >= 5) {
      showMessage('已经达到最大房屋数量')
      return
    }

    const buildCost = tile.price * 0.5 // 建房成本为地价的一半
    const currentPlayer = players.find(p => p.address === currentWallet.address)
    
    if (currentPlayer.balance < buildCost) {
      showMessage('余额不足建造房屋')
      return
    }

    // 建造房屋
    setGameState(prev => ({
      ...prev,
      board: prev.board.map(t => 
        t.position === position 
          ? { ...t, houses: t.houses + 1 }
          : t
      )
    }))

    const newBalance = currentPlayer.balance - buildCost
    setPlayers(prev => prev.map(player => 
      player.address === currentWallet.address 
        ? { ...player, balance: newBalance }
        : player
    ))

    updateBalance(currentWallet.address, newBalance)
    showMessage(`在 ${tile.name} 建造了房屋，花费 ${buildCost}`)
  }, [currentWallet, gameState.board, players, updateBalance])

  // 抵押地产
  const mortgageProperty = useCallback((position) => {
    // 实现抵押逻辑
    showMessage('抵押功能开发中...')
  }, [])

  // 支付出狱
  const payToLeaveJail = useCallback(() => {
    const currentPlayer = players.find(p => p.address === currentWallet.address)
    if (!currentPlayer?.isInJail) {
      showMessage('你不在监狱中')
      return
    }

    if (currentPlayer.balance < 50) {
      showMessage('余额不足支付出狱费用')
      return
    }

    const newBalance = currentPlayer.balance - 50
    setPlayers(prev => prev.map(player => 
      player.address === currentWallet.address 
        ? { 
            ...player, 
            balance: newBalance,
            isInJail: false,
            jailTurns: 0
          }
        : player
    ))

    updateBalance(currentWallet.address, newBalance)
    showMessage('支付50出狱成功')
  }, [currentWallet, players, updateBalance])

  // 获取当前玩家信息
  const getCurrentPlayer = useCallback(() => {
    return players.find(p => p.address === currentWallet?.address)
  }, [players, currentWallet])

  // 获取游戏信息
  const getGameInfo = useCallback(() => {
    return {
      state: gameState.state,
      currentPlayer: players[gameState.currentPlayerIndex],
      players: players
    }
  }, [gameState, players])

  return (
    <LocalGameContext.Provider value={{
      gameState,
      players,
      message,
      joinGame,
      startGame,
      rollDice,
      buyProperty,
      buildHouse,
      mortgageProperty,
      payToLeaveJail,
      getCurrentPlayer,
      getGameInfo,
      showMessage
    }}>
      {children}
    </LocalGameContext.Provider>
  )
}

export const useLocalGame = () => {
  const context = useContext(LocalGameContext)
  if (!context) {
    throw new Error('useLocalGame必须在LocalGameProvider内使用')
  }
  return context
}