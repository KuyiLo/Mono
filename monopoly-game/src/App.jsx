import React from 'react'
import GameBoard from './components/GameBoard/GameBoard'
import WalletSelector from './components/WalletSelector/WalletSelector'
import QuickPlayerSwitcher from './components/QuickPlayerSwitcher/QuickPlayerSwitcher'
import { LocalWalletProvider } from './hooks/useLocalWallet'
import { LocalGameProvider } from './hooks/useLocalGame'
import './styles/App.css'

function App() {
  return (
    <LocalWalletProvider>
      <LocalGameProvider>
        <div className="App">
          <header className="app-header">
            <h1>🎮 区块链大富翁 🏰</h1>
            <p>本地演示版本 - 无需Gas费用 - 多玩家测试版</p>
          </header>
          <main>
            <div className="app-layout">
              <aside className="sidebar">
                <WalletSelector />
                <QuickPlayerSwitcher />
                <div className="game-instructions">
                  <h4>游戏说明</h4>
                  <ul>
                    <li>💰 起始资金: 1500</li>
                    <li>🎯 目标: 成为最富有的玩家</li>
                    <li>🎲 掷骰子移动</li>
                    <li>🏠 购买无人地产</li>
                    <li>💵 支付他人地产租金</li>
                    <li>🚓 小心入狱!</li>
                  </ul>
                </div>
              </aside>
              <section className="main-content">
                <GameBoard />
              </section>
            </div>
          </main>
        </div>
      </LocalGameProvider>
    </LocalWalletProvider>
  )
}

export default App