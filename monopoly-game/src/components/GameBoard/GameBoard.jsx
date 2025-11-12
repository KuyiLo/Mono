import React from 'react'
import { useWeb3 } from '../../hooks/useWeb3.jsx'
import './GameBoard.css'

const GameBoard = () => {
  const { account, isConnected, connectWallet } = useWeb3()

  if (!isConnected) {
    return (
      <div className="connect-wallet-container">
        <div className="wallet-card">
          <h2>🔗 连接钱包开始游戏</h2>
          <p>请连接您的MetaMask钱包来体验区块链大富翁</p>
          <button onClick={connectWallet} className="connect-button">
            🦊 连接MetaMask
          </button>
          <div className="wallet-tips">
            <h4>使用提示：</h4>
            <ul>
              <li>确保已安装MetaMask浏览器扩展</li>
              <li>选择以太坊测试网络（如Sepolia）</li>
              <li>准备少量测试ETH支付Gas费</li>
            </ul>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="game-board">
      <div className="player-info-bar">
        <div className="wallet-info">
          <span>👤 玩家: {account.slice(0, 6)}...{account.slice(-4)}</span>
        </div>
        <div className="game-status">
          <span>🎯 状态: 准备中</span>
        </div>
      </div>
      
      <div className="board-container">
        <div className="board">
          <div className="tile start-tile">
            <div className="tile-content">
              <div className="tile-name">起点</div>
              <div className="tile-effect">经过+200</div>
            </div>
          </div>
          
          <div className="tile property-tile">
            <div className="tile-content">
              <div className="tile-name">地中海大道</div>
              <div className="tile-price">💰 60</div>
            </div>
          </div>

          <div className="tile chance-tile">
            <div className="tile-content">
              <div className="tile-name">机会</div>
              <div className="tile-effect">抽卡</div>
            </div>
          </div>

          <div className="tile tax-tile">
            <div className="tile-content">
              <div className="tile-name">所得税</div>
              <div className="tile-effect">支付200</div>
            </div>
          </div>
        </div>
      </div>

      <div className="control-panel">
        <h3>游戏控制</h3>
        <div className="control-buttons">
          <button className="control-btn primary">加入游戏</button>
          <button className="control-btn secondary">掷骰子</button>
          <button className="control-btn">查看资产</button>
        </div>
        
        <div className="game-info">
          <h4>开发进度</h4>
          <ul>
            <li>✅ 钱包连接功能</li>
            <li>🔄 游戏界面框架</li>
            <li>⏳ 智能合约集成</li>
            <li>⏳ 完整游戏逻辑</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default GameBoard