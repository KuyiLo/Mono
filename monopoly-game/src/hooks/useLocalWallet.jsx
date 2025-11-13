import React, { createContext, useContext, useState, useEffect } from 'react'

const LocalWalletContext = createContext()

// 模拟的玩家数据
const mockPlayers = [
  {
    address: '0xPlayer1',
    privateKey: 'mock-private-key-1',
    balance: 1500,
    nickname: '玩家1'
  },
  {
    address: '0xPlayer2', 
    privateKey: 'mock-private-key-2',
    balance: 1500,
    nickname: '玩家2'
  },
  {
    address: '0xPlayer3',
    privateKey: 'mock-private-key-3', 
    balance: 1500,
    nickname: '玩家3'
  },
  {
    address: '0xPlayer4',
    privateKey: 'mock-private-key-4',
    balance: 1500,
    nickname: '玩家4'
  }
]

export const LocalWalletProvider = ({ children }) => {
  const [wallets, setWallets] = useState([])
  const [currentWallet, setCurrentWallet] = useState(null)
  const [isConnected, setIsConnected] = useState(false)

  // 初始化钱包
  useEffect(() => {
    setWallets(mockPlayers)
    
    // 尝试从本地存储恢复上次连接的钱包
    const savedWallet = localStorage.getItem('monopoly-current-wallet')
    if (savedWallet) {
      setCurrentWallet(JSON.parse(savedWallet))
      setIsConnected(true)
    }
  }, [])

  // 连接钱包
  const connectWallet = (walletIndex) => {
    const wallet = wallets[walletIndex]
    setCurrentWallet(wallet)
    setIsConnected(true)
    localStorage.setItem('monopoly-current-wallet', JSON.stringify(wallet))
  }

  // 断开连接
  const disconnectWallet = () => {
    setCurrentWallet(null)
    setIsConnected(false)
    localStorage.removeItem('monopoly-current-wallet')
  }

  // 更新钱包余额
  const updateBalance = (address, newBalance) => {
    setWallets(prev => prev.map(wallet => 
      wallet.address === address ? { ...wallet, balance: newBalance } : wallet
    ))
    
    if (currentWallet && currentWallet.address === address) {
      setCurrentWallet(prev => ({ ...prev, balance: newBalance }))
      localStorage.setItem('monopoly-current-wallet', JSON.stringify({
        ...currentWallet,
        balance: newBalance
      }))
    }
  }

  // 获取所有钱包
  const getWallets = () => wallets

  return (
    <LocalWalletContext.Provider value={{
      wallets: getWallets(),
      currentWallet,
      isConnected,
      connectWallet,
      disconnectWallet,
      updateBalance
    }}>
      {children}
    </LocalWalletContext.Provider>
  )
}

export const useLocalWallet = () => {
  const context = useContext(LocalWalletContext)
  if (!context) {
    throw new Error('useLocalWallet必须在LocalWalletProvider内使用')
  }
  return context
}