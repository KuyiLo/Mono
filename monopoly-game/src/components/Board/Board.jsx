import React from 'react'
import { useLocalGame } from '../../hooks/useLocalGame'
import { useLocalWallet } from '../../hooks/useLocalWallet'
import { boardData, getTileColorClass } from '../../utils/boardData'
import './Board.css'

const Board = () => {
  const { gameState, players } = useLocalGame()
  const { currentWallet } = useLocalWallet()

  const renderTile = (tile) => {
    const tilePlayers = players.filter(p => p.position === tile.position)
    const isOwned = tile.owner !== null
    const owner = isOwned ? players.find(p => p.address === tile.owner) : null
    const isCurrentPlayer = currentWallet && tilePlayers.some(p => p.address === currentWallet.address)
    
    return (
      <div 
        key={tile.position} 
        className={`tile ${tile.type}-tile ${getTileColorClass(tile)} ${isCurrentPlayer ? 'current-player' : ''}`}
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
            <div className="tile-owner">
              👑{owner?.nickname.charAt(0)}
            </div>
          )}
          
          {tile.houses > 0 && (
            <div className="tile-houses">
              {Array.from({ length: Math.min(tile.houses, 5) }).map((_, i) => (
                <span key={i} className="house">🏠</span>
              ))}
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
    <div className="board-container">
      <div className="board">
        {/* 顶部行 */}
        <div className="board-row top-row">
          {boardData.slice(0, 11).map(renderTile)}
        </div>
        
        <div className="board-middle">
          {/* 右侧列 */}
          <div className="board-column right-column">
            {boardData.slice(11, 20).map(renderTile)}
          </div>
          
          {/* 中心区域 */}
          <div className="board-center">
            <div className="center-content">
              <h3>🎮 大富翁</h3>
              <div className="game-info">
                <p>本地演示版</p>
                <p>无需Gas费用</p>
              </div>
            </div>
          </div>
          
          {/* 左侧列 */}
          <div className="board-column left-column">
            {boardData.slice(31, 40).reverse().map(renderTile)}
          </div>
        </div>
        
        {/* 底部行 */}
        <div className="board-row bottom-row">
          {boardData.slice(21, 31).reverse().map(renderTile)}
        </div>
      </div>
    </div>
  )
}

export default Board