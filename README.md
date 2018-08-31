# Decentralised Lottery

## Requirements

- Install MetaMask [extension](https://metamask.io/)
- Remix - Solidity [IDE](https://remix.ethereum.org/#optimize=true)
- INFURA keys from [here](https://infura.io/). This will enable us to work with Ropsten TestNet without hosting our own node. Infura will do the heavy lifting for us!

These are all the tools you need to delpoy the smart contracts and interact with it!

## Deployment

- Create ethereum account using MetaMask. Make sure to choose "Ropsten Test Network"
- Request few ethers from the test [faucet](https://faucet.metamask.io/)
- Go to Remix solidity IDE and copy-paste the contents of lottery.sol file in the IDE.
- Click on "Start to compile" from the Compile tab in the top right corner.
- After compiling it, go to Run tab and click on "deploy". Metamask should bring up a popup asking you to confirm the transaction. If not, just open the Metamask extension and do it there.
- A message at the bottom of the Remix console will notify you when the contract is deployed. You can click on the link to explore the transaction on [ropsten.etherscan.io](https://ropsten.etherscan.io/). Note the contracts address!
