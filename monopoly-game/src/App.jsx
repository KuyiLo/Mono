import React from 'react'
import GameBoard from './components/GameBoard/GameBoard'
import { Web3Provider } from './hooks/useWeb3.jsx'  // 添加.jsx扩展名
import './styles/App.css'

function App() {
  return (
    <Web3Provider>
      <div className="App">
        <header className="app-header">
          <h1>🎮 区块链大富翁 🏰</h1>
          <p>基于以太坊的去中心化桌游体验</p>
        </header>
        <main>
          <GameBoard />
        </main>
      </div>
    </Web3Provider>
  )
}

export default App