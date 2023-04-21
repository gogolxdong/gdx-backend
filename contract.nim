import std/[random,options, json, parseutils, strutils, strformat, times, tables, sugar, sequtils, os]
import pkg/[web3, chronos, nimcrypto, eth/keys, stint, puppy, taskpools, stint, web3/ethtypes]

# contract(PancakeRouter):
#   proc WETH(): Address
#   proc factory(): Address
#   proc removeLiquidityETHSupportingFeeOnTransferTokens(token: Address,liquidity: Uint, amountTokenMin, amountEthMin: Uint256, to: Address, deadLine: Uint): Uint {.view.}
#   proc swapExactTokensForTokens(amountIn: Uint256, amountOutMin: Uint256, path: openArray[Address], to: Address, deadLine: Uint256)
#   proc swapExactETHForTokens(amountOutMin: Uint256, path: openArray[Address], to: Address, deadLine: Uint256)

const zeroAddress* = "0x0000000000000000000000000000000000000000"
const gridFactoryAddress* = Address.fromHex "0x0bF7dE8d71820840063D4B8653Fd3F0618986faF"

const rpcs* = ["http://45.76.158.181:8545"]
randomize(now().toTime.toUnix)
var rpc* = rpcs.sample()

# template useGridFactory*(body: untyped) {.dirty.} =
#   let snapshotWeb3 = waitFor newWeb3(rpc)
#   let snapshot = snapshotWeb3.contractSender(GridFactory, gridFactoryAddress)
#   body
#   waitFor snapshotWeb3.close()
