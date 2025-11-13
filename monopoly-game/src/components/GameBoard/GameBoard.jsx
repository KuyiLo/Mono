import React from 'react'
import { useLocalWallet } from '../../hooks/useLocalWallet'
import { useLocalGame } from '../../hooks/useLocalGame'
import SimpleBoard from '../Board/SimpleBoard'
import './GameBoard.css'

const GameBoard = () => {
  const { currentWallet, isConnected } = useLocalWallet()
  const { 
    gameState, 
    players, 
    message,
    joinGame, 
    startGame, 
    rollDice, 
    buyProperty,
    payToLeaveJail,
    getCurrentPlayer,
    getGameInfo,
  } = useLocalGame()

  const currentPlayer = getCurrentPlayer()
  const gameInfo = getGameInfo()

  if (!isConnected) {
    return (
      <div className="connect-wallet-container">
        <div className="wallet-card">
          <h2>🎮 欢迎来到区块链大富翁</h2>
          <p>请在左侧选择玩家身份开始游戏</p>
          <div className="local-features">
            <h4>多玩家测试版特色：</h4>
            <ul>
              <li>✅ 完全免费，无需Gas费用</li>
              <li>✅ 快速玩家切换</li>
              <li>✅ 多玩家同时游戏</li>
              <li>✅ 完整的游戏逻辑</li>
              <li>✅ 简化棋盘布局</li>
              <li>✅ 实时状态显示</li>
            </ul>
          </div>
        </div>
      </div>
    )
  }

  // 游戏状态文本映射
  const gameStateText = {
    0: '未开始',
    1: '进行中', 
    2: '暂停',
    3: '已结束'
  }

  const isMyTurn = currentPlayer && gameInfo.currentPlayer && 
                   currentPlayer.address === gameInfo.currentPlayer.address

  return (
    <div className="game-board">
      {/* 消息提示 */}
      {message && (
        <div className="message-overlay">
          <div className="message-box">
            {message}
          </div>
        </div>
      )}
      
      <div className="player-info-bar">
        <div className="wallet-info">
          <span>👤 {currentWallet.nickname}</span>
          <span className="balance">余额: {currentWallet.balance}💰</span>
          {currentPlayer && (
            <>
              <span className="position">位置: {currentPlayer.position}</span>
              {currentPlayer.isInJail && (
                <span className="jail-status">🚓 在监狱中</span>
              )}
              {isMyTurn && (
                <span className="turn-indicator">🎯 你的回合!</span>
              )}
            </>
          )}
        </div>
        <div className="game-status">
          <span>🎮 状态: {gameStateText[gameState.state]}</span>
          {gameInfo.currentPlayer && (
            <span className="current-turn">
              当前回合: {players.find(p => p.address === gameInfo.currentPlayer.address)?.nickname}
            </span>
          )}
        </div>
      </div>
      
      {/* 使用简化棋盘 */}
      <SimpleBoard />
      
      <div className="control-panel">
        <h3>游戏控制</h3>
        <div className="control-buttons">
          <button onClick={joinGame} className="control-btn primary" disabled={currentPlayer}>
            {currentPlayer ? '✅ 已加入' : '加入游戏'}
          </button>
          <button onClick={startGame} className="control-btn secondary" disabled={gameState.state !== 0}>
            开始游戏
          </button>
          <button onClick={rollDice} className="control-btn" disabled={!isMyTurn || gameState.state !== 1}>
            {isMyTurn ? '掷骰子' : '等待回合'}
          </button>
          <button onClick={buyProperty} className="control-btn" disabled={!isMyTurn}>
            购买地产
          </button>
          {currentPlayer?.isInJail && (
            <button onClick={payToLeaveJail} className="control-btn jail-btn">
              支付出狱 (50)
            </button>
          )}
        </div>
        
        <div className="game-info">
          <h4>玩家信息</h4>
          {currentPlayer ? (
            <div className="player-details">
              <p>💰 余额: {currentPlayer.balance}</p>
              <p>📍 位置: {currentPlayer.position}</p>
              <p>🏠 地产: {currentPlayer.properties.length}处</p>
              <p>🚓 状态: {currentPlayer.isInJail ? '在监狱' : '自由'}</p>
              {currentPlayer.isInJail && (
                <p>⏳ 监狱回合: {currentPlayer.jailTurns}</p>
              )}
            </div>
          ) : (
            <p>请先加入游戏</p>
          )}
          
          <h4>游戏状态</h4>
          <div className="game-details">
            <p>🎮 状态: {gameStateText[gameState.state]}</p>
            <p>👥 玩家数: {players.length}/4</p>
            {gameInfo.currentPlayer && (
              <p>👑 当前回合: {players.find(p => p.address === gameInfo.currentPlayer.address)?.nickname}</p>
            )}
          </div>
          
          <h4>所有玩家</h4>
          <div className="players-list">
            {players.map(player => (
              <div key={player.address} className={`player-item ${player.address === currentWallet.address ? 'current' : ''} ${player.address === gameInfo.currentPlayer?.address ? 'active-turn' : ''}`}>
                <span className="player-name">{player.nickname}</span>
                <span className="player-balance">💰{player.balance}</span>
                <span className="player-position">📍{player.position}</span>
                <span className="player-properties">🏠{player.properties.length}</span>
                {player.isInJail && <span className="player-jail">🚓</span>}
                {player.address === gameInfo.currentPlayer?.address && <span className="player-turn">🎯</span>}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default GameBoard