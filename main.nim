import pkg/[web3,chronos, stint, nimcrypto/keccak]
import std/[options, json, strutils]

const placeMarketOrderSignature = "PlaceMakerOrder(uint256,address,uint64,bool,int24,uint128)"

echo "0x" & toLowerAscii($keccak256.digest(placeMarketOrderSignature))
contract(Grid):
    proc PlaceMakerOrder(orderId: indexed[UInt256],recipient:indexed[Address], bundleId: FixedBytes[64], zero:Bool, boundaryLower: FixedBytes[24], amount: FixedBytes[128]) {.event.}

contract(SwapRouterHub):
  proc Swap(sender: indexed[Address], recipient: indexed[Address], amount0: UInt256,  amount1: UInt256,  priceX96: UInt256, boundary: UInt256) {.event.}

var contractAddress = Address.fromHex("0x0bF7dE8d71820840063D4B8653Fd3F0618986faF")
var gridAddress = Address.fromHex("0x5E5713a0d915701F464DEbb66015adD62B2e6AE9")

proc test() {.async.} =
    let web3 = await newWeb3("ws://127.0.0.1:8545/")
    let accounts = await web3.provider.eth_accounts()
    echo "accounts: ", accounts
    web3.defaultAccount = accounts[0]
    echo "block: ", uint64(await web3.provider.eth_blockNumber())

    let notifFut = newFuture[void]()
    proc errorHandler(err: CatchableError) = echo "Error from MyEvent subscription: ", err.msg

    # let grid = web3.contractSender(Grid, gridAddress)
    # proc placeMakerOrderHandler(orderId:UInt256, recipient:Address, bundleId:UInt256, zero:UInt256, boundaryLower:UInt256, amount: UInt256){.raises: [Defect], gcsafe.}=
    #     try:
    #         echo "onEvent: ", orderId, recipient, bundleId, zero, boundaryLower, amount
    #     except Exception as err:
    #         doAssert false, err.msg
    # let s = await grid.subscribe(PlaceMakerOrder, %*{"fromBlock": "0x0"},placeMakerOrderHandler ,errorHandler) 
    # await notifFut

    proc eventHandler(json:JsonNode)=
        echo json

    let s = await web3.subscribeForLogs(%*{"fromBlock": "0x103FC6C"}, eventHandler ,errorHandler) 
    await notifFut

    # proc listenSwaps(sender: Address, recipient: Address, amount0: UInt256,  amount1: UInt256,  priceX96: UInt256, boundary: UInt256){.raises: [Defect], gcsafe.}=
    #     try:
    #         echo "onEvent: ", sender
    #     except Exception as err:
    #         doAssert false, err.msg
    # let swapRouterHub = web3.contractSender(SwapRouterHub, contractAddress)
    # let s = await swapRouterHub.subscribe(Swap, %*{"fromBlock": "0x0"}, listenSwaps, errorHandler) 
    # await notifFut

    # await s.unsubscribe()
    # await web3.close()

waitFor test()
