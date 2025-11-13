import React from 'react'
import { useLocalWallet } from '../../hooks/useLocalWallet'
import { useLocalGame } from '../../hooks/useLocalGame'
import './WalletSelector.css'

const WalletSelector = () => {
  const { wallets, currentWallet, connectWallet, disconnectWallet, isConnected } = useLocalWallet()
  const { players, joinGame } = useLocalGame()

  // 检查玩家是否已加入游戏
  const isPlayerJoined = (walletAddress) => {
    return players.some(player => player.address === walletAddress)
  }

  if (isConnected) {
    const isCurrentPlayerJoined = isPlayerJoined(currentWallet.address)
    
    return (
      <div className="wallet-selector connected">
        <div className="wallet-info">
          <span className="wallet-avatar">👤</span>
          <div className="wallet-details">
            <div className="wallet-nickname">{currentWallet.nickname}</div>
            <div className="wallet-address">{currentWallet.address}</div>
            <div className="wallet-balance">余额: {currentWallet.balance} 💰</div>
            <div className={`join-status ${isCurrentPlayerJoined ? 'joined' : 'not-joined'}`}>
              {isCurrentPlayerJoined ? '✅ 已加入游戏' : '❌ 未加入游戏'}
            </div>
          </div>
        </div>
        <div className="wallet-actions">
          {!isCurrentPlayerJoined && (
            <button onClick={joinGame} className="join-btn">
              加入游戏
            </button>
          )}
          <button onClick={disconnectWallet} className="disconnect-btn">
            断开连接
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="wallet-selector">
      <h3>选择玩家身份</h3>
      <div className="wallet-list">
        {wallets.map((wallet, index) => (
          <div key={wallet.address} className="wallet-item">
            <div className="wallet-avatar">👤</div>
<div className="wallet-details">
              <div className="wallet-nickname">{wallet.nickname}</div>
              <div className="wallet-address">{wallet.address}</div>
              <div className="wallet-balance">余额: {wallet.balance} 💰</div>
            </div>
            <button 
              onClick={() => connectWallet(index)} 
              className="connect-btn"
            >
              连接
            </button>
          </div>
        ))}
      </div>
      
      <div className="multiplayer-tips">
        <h4>多玩家测试指南：</h4>
        <ol>
          <li>连接第一个玩家 → 点击"加入游戏"</li>
          <li>断开连接 → 连接第二个玩家 → 点击"加入游戏"</li>
          <li>重复以上步骤添加更多玩家</li>
          <li>所有玩家加入后，点击"开始游戏"</li>
        </ol>
      </div>
    </div>
  )
}

export default WalletSelector