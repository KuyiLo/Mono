import React, { createContext, useContext, useState, useEffect } from 'react'
import Web3 from 'web3'
import { CONTRACT_ADDRESS, MonopolyABI } from '../contracts/contractConfig'

const Web3Context = createContext()

export const Web3Provider = ({ children }) => {
  const [web3, setWeb3] = useState(null)
  const [account, setAccount] = useState('')
  const [contract, setContract] = useState(null)
  const [isConnected, setIsConnected] = useState(false)

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        await window.ethereum.request({ method: 'eth_requestAccounts' })
        const web3Instance = new Web3(window.ethereum)
        const accounts = await web3Instance.eth.getAccounts()
        
        setWeb3(web3Instance)
        setAccount(accounts[0])
        setIsConnected(true)
        
        // 初始化合约实例
        const contractInstance = new web3Instance.eth.Contract(
          MonopolyABI,
          CONTRACT_ADDRESS
        )
        setContract(contractInstance)
        
        console.log('钱包连接成功:', accounts[0])
        console.log('合约实例创建成功:', CONTRACT_ADDRESS)
      } catch (error) {
        console.error('连接钱包失败:', error)
        alert('连接钱包失败，请确保已安装MetaMask并解锁')
      }
    } else {
      alert('请安装MetaMask钱包!')
    }
  }

  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.request({ method: 'eth_accounts' })
        .then(accounts => {
          if (accounts.length > 0) {
            const web3Instance = new Web3(window.ethereum)
            setWeb3(web3Instance)
            setAccount(accounts[0])
            setIsConnected(true)
            
            // 初始化合约
            const contractInstance = new web3Instance.eth.Contract(
              MonopolyABI,
              CONTRACT_ADDRESS
            )
            setContract(contractInstance)
          }
        })
    }
  }, [])

  return (
    <Web3Context.Provider value={{
      web3,
      account,
      contract,
      isConnected,
      connectWallet
    }}>
      {children}
    </Web3Context.Provider>
  )
}

export const useWeb3 = () => {
  const context = useContext(Web3Context)
  if (!context) {
    throw new Error('useWeb3必须在Web3Provider内使用')
  }
  return context
}