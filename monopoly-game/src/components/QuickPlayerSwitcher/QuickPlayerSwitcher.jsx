import React from 'react'
import { useLocalWallet } from '../../hooks/useLocalWallet'
import { useLocalGame } from '../../hooks/useLocalGame'
import './QuickPlayerSwitcher.css'

const QuickPlayerSwitcher = () => {
  const { wallets, currentWallet, connectWallet } = useLocalWallet()
  const { players } = useLocalGame()

  if (!currentWallet) return null

  const getPlayerStatus = (wallet) => {
    const player = players.find(p => p.address === wallet.address)
    if (!player) return { status: 'not-joined', text: '未加入' }
    
    return { 
      status: 'joined', 
      text: `已加入 (💰${player.balance})`
    }
  }

  return (
    <div className="quick-switcher">
      <h4>快速切换玩家</h4>
      <div className="player-buttons">
        {wallets.map((wallet, index) => {
          const { status, text } = getPlayerStatus(wallet)
          const isCurrent = wallet.address === currentWallet.address
          
          return (
            <button
              key={wallet.address}
              onClick={() => !isCurrent && connectWallet(index)}
              className={`player-btn ${status} ${isCurrent ? 'current' : ''}`}
              disabled={isCurrent}
              title={isCurrent ? '当前玩家' : `切换到 ${wallet.nickname}`}
            >
              <span className="player-avatar">👤</span>
              <span className="player-name">{wallet.nickname}</span>
              <span className="player-status">{text}</span>
            </button>
          )
        })}
      </div>
    </div>
  )
}

export default QuickPlayerSwitcher