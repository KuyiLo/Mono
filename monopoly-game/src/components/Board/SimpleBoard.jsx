import React from 'react'
import { useLocalGame } from '../../hooks/useLocalGame'
import { useLocalWallet } from '../../hooks/useLocalWallet'
import { boardData } from '../../utils/boardData'
import './SimpleBoard.css'

const SimpleBoard = () => {
  const { gameState, players } = useLocalGame()
  const { currentWallet } = useLocalWallet()

  const renderTile = (tile, index) => {
    const tilePlayers = players.filter(p => p.position === tile.position)
    const isOwned = tile.owner !== null
    const owner = isOwned ? players.find(p => p.address === tile.owner) : null
    const isCurrentPlayer = currentWallet && tilePlayers.some(p => p.address === currentWallet.address)
    
    return (
      <div 
        key={tile.position} 
        className={`tile ${tile.type}-tile ${isCurrentPlayer ? 'current-player' : ''}`}
        style={{ gridArea: `pos${tile.position}` }}
      >
        <div className="tile-content">
          <div className="tile-name">{tile.name}</div>
          
          {tile.price && (
            <div className="tile-price">💰{tile.price}</div>
          )}
          
          {tile.effect && (
            <div className="tile-effect">{tile.effect}</div>
          )}
          
          {isOwned && (
            <div className="tile-owner" title={`所有者: ${owner?.nickname}`}>
              👑
            </div>
          )}
          
          <div className="tile-players">
            {tilePlayers.map(player => (
              <div 
                key={player.address} 
                className={`player-marker ${player.address === currentWallet?.address ? 'current' : ''}`}
                title={player.nickname}
              >
                {player.nickname.charAt(0)}
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="simple-board-container">
      <div className="simple-board">
        {boardData.map((tile, index) => renderTile(tile, index))}
      </div>
    </div>
  )
}

export default SimpleBoard