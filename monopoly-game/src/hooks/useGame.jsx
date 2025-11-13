import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { useWeb3 } from './useWeb3'

const GameContext = createContext()

export const GameProvider = ({ children }) => {
  const { contract, account } = useWeb3()
  const [gameState, setGameState] = useState(null)
  const [currentPlayer, setCurrentPlayer] = useState(null)
  const [properties, setProperties] = useState([])

  // 获取游戏状态
  const fetchGameState = useCallback(async () => {
    if (!contract || !account) return

    try {
      console.log('开始获取游戏状态...')
      
      // 获取当前游戏状态
      const state = await contract.methods.currentState().call()
      const currentPlayerAddr = await contract.methods.getCurrentPlayer().call()
      const playerInfo = await contract.methods.getPlayerInfo(account).call()
      
      console.log('游戏状态数据:', {
        state: Number(state),
        currentPlayer: currentPlayerAddr,
        playerInfo
      })
      
      setGameState({
        state: Number(state),
        currentPlayer: currentPlayerAddr
      })
      
      setCurrentPlayer({
        address: account,
        balance: Number(playerInfo.balance),
        position: Number(playerInfo.position),
        isInJail: playerInfo.isInJail,
        isActive: playerInfo.isActive
      })

    } catch (error) {
      console.error('获取游戏状态失败:', error)
    }
  }, [contract, account])

  // 加入游戏
  const joinGame = async () => {
    try {
      console.log('尝试加入游戏...')
      await contract.methods.joinGame().send({ from: account })
      await fetchGameState()
      alert('成功加入游戏！')
    } catch (error) {
      console.error('加入游戏失败:', error)
      alert('加入游戏失败: ' + error.message)
    }
  }

  // 开始游戏
  const startGame = async () => {
    try {
      console.log('尝试开始游戏...')
      await contract.methods.startGame().send({ from: account })
      await fetchGameState()
      alert('游戏开始！')
    } catch (error) {
      console.error('开始游戏失败:', error)
      alert('开始游戏失败: ' + error.message)
    }
  }

  // 掷骰子
  const rollDice = async () => {
    try {
      console.log('尝试掷骰子...')
      await contract.methods.rollDice().send({ from: account })
      await fetchGameState()
    } catch (error) {
      console.error('掷骰子失败:', error)
      alert('掷骰子失败: ' + error.message)
    }
  }

  // 购买地产
  const buyProperty = async () => {
    try {
      if (!currentPlayer) {
        alert('请先获取玩家信息')
        return
      }
      
      console.log('尝试购买地产，当前位置:', currentPlayer.position)
      
      // 获取当前位置的格子信息
      const tile = await contract.methods.board(currentPlayer.position).call()
      console.log('当前位置格子信息:', tile)
      
      if (Number(tile.tileType) === 0) { // 0 代表 Property
        await contract.methods.buyProperty(tile.propertyId).send({ from: account })
        await fetchGameState()
        alert('购买成功！')
      } else {
        alert('当前位置无法购买地产')
      }
    } catch (error) {
      console.error('购买地产失败:', error)
      alert('购买地产失败: ' + error.message)
    }
  }

  // 建造房屋
  const buildHouse = async (propertyId) => {
    try {
      await contract.methods.buildHouse(propertyId).send({ from: account })
      await fetchGameState()
      alert('建造房屋成功！')
    } catch (error) {
      console.error('建造房屋失败:', error)
      alert('建造房屋失败: ' + error.message)
    }
  }

  // 初始加载游戏状态
  useEffect(() => {
    if (contract && account) {
      fetchGameState()
    }
  }, [contract, account, fetchGameState])

  return (
    <GameContext.Provider value={{
      gameState,
      currentPlayer,
      properties,
      joinGame,
      startGame,
      rollDice,
      buyProperty,
      buildHouse,
      fetchGameState
    }}>
      {children}
    </GameContext.Provider>
  )
}

export const useGame = () => {
  const context = useContext(GameContext)
  if (!context) {
    throw new Error('useGame必须在GameProvider内使用')
  }
  return context
}