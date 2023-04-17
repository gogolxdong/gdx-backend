import pkg/[web3,chronos, stint, nimcrypto/keccak]
import std/[options, json, strutils, tables, times, strformat]

const placeMarketOrderSignature = "PlaceMakerOrder(uint256,address,uint64,bool,int24,uint128)"
const swapSignature = "Swap(address,address,int256,int256,uint160,int24)"

echo "placeMarketOrderSignature: 0x" & toLowerAscii($keccak256.digest(placeMarketOrderSignature))
echo "swapSignature: 0x" & toLowerAscii($keccak256.digest(swapSignature))

contract(Grid):
    proc PlaceMakerOrder(orderId: indexed[UInt256],recipient:indexed[Address], bundleId: FixedBytes[64], zero:Bool, boundaryLower: FixedBytes[24], amount: FixedBytes[128]) {.event.}

contract(SwapRouterHub):
  proc Swap(sender: indexed[Address], recipient: indexed[Address], amount0: UInt256,  amount1: UInt256,  priceX96: UInt256, boundary: UInt256) {.event.}

var contractAddress = Address.fromHex("0x0bF7dE8d71820840063D4B8653Fd3F0618986faF")
var gridAddress = Address.fromHex("0x5E5713a0d915701F464DEbb66015adD62B2e6AE9")

proc main() {.async.} =
    var web3 = await newWeb3("ws://127.0.0.1:8545/")
    let accounts = await web3.provider.eth_accounts()
    echo "accounts: ", accounts
    web3.defaultAccount = accounts[0]
    echo "block: ", uint64(await web3.provider.eth_blockNumber())

    let notifFut = newFuture[void]()
    proc errorHandler(err: CatchableError) = echo "Error from MyEvent subscription: ", err.msg

    var logs = newJArray()
    proc eventHandler(json:JsonNode) {.gcsafe, raises: [Defect].} =
        try:
            if web3.subscriptions.len == 0:
                waitFor web3.close()
                web3 = waitFor newWeb3("http://127.0.0.1:8545")
            echo now(), " ",json
            logs.add(json)
            writeFile("logs.json", $logs)
        except:
            echo getCurrentExceptionMsg()

    let s = await web3.subscribeForLogs(%*{"fromBlock": "latest"}, eventHandler ,errorHandler) 
    await notifFut

    proc handleSwap(sender: Address, recipient: Address, amount0: UInt256,  amount1: UInt256,  priceX96: UInt256, boundary: UInt256){.raises: [Defect], gcsafe.}=
        try:
            echo &"sender:{sender} recipient:{recipient} amount0:{amount0} amount1:{amount1} priceX96:{priceX96}, boundary:{boundary}"
        except Exception as err:
            doAssert false, err.msg

    # let swapRouterHub = web3.contractSender(SwapRouterHub, contractAddress)
    # let s = await swapRouterHub.subscribe(Swap, %*{"fromBlock": "latest"}, handleSwap, errorHandler) 
    # await notifFut

    proc handlePlaceMakerOrder(orderId: UInt256,recipient: Address, bundleId: FixedBytes[64], zero:Bool, boundaryLower: FixedBytes[24], amount: FixedBytes[128])=
        try:
            echo &"orderId:{orderId} recipient:{recipient} bundleId:{bundleId} zero:{zero} boundaryLower:{boundaryLower}, amount:{amount}"
        except Exception as err:
            doAssert false, err.msg
    # let grid = web3.contractSender(Grid, gridAddress)
    # let s = await grid.subscribe(PlaceMakerOrder, %*{"fromBlock": "latest"}, handlePlaceMakerOrder, errorHandler) 
    # await notifFut
    # await s.unsubscribe()
    # await web3.close()

waitFor main()
