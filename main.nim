import std/[options, json, strutils, tables, times, strformat]
import pkg/[web3,chronos, stint, nimcrypto/keccak, web3/ethtypes]

#PlaceMakerOrder(uint256,address,bytes64,bool,bytes24,bytes128)
const placeMarketOrder = "PlaceMakerOrder(uint256,address,uint64,bool,int24,uint128)" 
const swap = "Swap(address,address,int256,int256,uint160,int24)"

const placeMarketOrderSignature = &"0x{toLowerAscii($keccak256.digest(placeMarketOrder))}"
const swapSignature = &"0x{toLowerAscii($keccak256.digest(swap))}"

contract(Grid):
    proc PlaceMakerOrder(orderId: indexed[UInt256], recipient:indexed[Address], bundleId: indexed[Uint64], zero:Bool, boundaryLower: Int24, amount: StUint[128]) {.event.}

contract(SwapRouterHub):
  proc Swap(sender: indexed[Address], recipient: indexed[Address], amount0: StInt[256],  amount1: StInt[256],  priceX96: UInt160, boundary: Int24) {.event.}

var swapRouterAddress = Address.fromHex("0xf4AE7E15B1012edceD8103510eeB560a9343AFd3")
var gridAddress = Address.fromHex("0xe8afd1fa3f91fa7387b0537bda5c525752efe821")

proc main() {.async.} =
    var web3 = await newWeb3("ws://127.0.0.1:28545/")
    let accounts = await web3.provider.eth_accounts()
    web3.defaultAccount = accounts[0]
    echo "block: ", uint64(await web3.provider.eth_blockNumber())

    let notifFut = newFuture[void]()
    proc errorHandler(err: CatchableError) = echo "Error from MyEvent subscription: ", err.msg

    var logs = newJArray()
    proc eventHandler(j:JsonNode) {.gcsafe, raises: [Defect].} =
        try:
            if web3.subscriptions.len == 0:
                waitFor web3.close()
                web3 = waitFor newWeb3("http://127.0.0.1:28545")

            echo j["topics"]
            var topics = j["topics"][0].getStr
            echo now(),": ", topics, " ",placeMarketOrderSignature
            if topics == placeMarketOrderSignature:
                var orderId: UInt256
                echo decode(strip0xPrefix j["topics"][1].getStr, 0, orderId)
                echo "orderId:",orderId

                var recipient: Address
                discard decode(strip0xPrefix j["topics"][2].getStr, 0, recipient)
                echo "recipient:",recipient

                var bundleId: Uint64
                discard decode(strip0xPrefix j["topics"][3].getStr, 0, bundleId)
                echo "bundleId:",bundleId
                var inputData = strip0xPrefix j["data"].getStr
                var offset = 0

                var zero: Bool
                var zeroDecodeLen = decode(inputData, offset, zero)
                offset += zeroDecodeLen
                echo &"{zeroDecodeLen} zero:",zero

                var boundaryLower: Int24
                var boundaryLowerDecodeLen = decode(inputData, offset, boundaryLower)
                offset += boundaryLowerDecodeLen
                echo &"{boundaryLowerDecodeLen} boundaryLower:",boundaryLower

                var amount: StUint[128]
                offset += decode(inputData, offset, amount)
                echo &"amount:{amount.toString()}"
            elif topics == swapSignature:
                var sender: Address
                echo decode(strip0xPrefix j["topics"][1].getStr, 0, sender)
                echo "sender:",sender
                
                var recipient: Address
                discard decode(strip0xPrefix j["topics"][2].getStr, 0, recipient)
                echo "recipient:",recipient

            
                var inputData = strip0xPrefix j["data"].getStr
                var offset:int = 0

                var amount0 = Int256.fromHex("0x0")
                discard decode(inputData, offset, amount0)
                echo "amount0:",amount0

                var amount1 = Int256.fromHex("0x0")
                var amount1DecodeLen = decode(inputData, offset, amount1)
                offset += amount1DecodeLen
                echo &"{amount1DecodeLen} amount1:",amount1

                var priceX96 = UInt160.fromHex("0x0")
                offset += decode(inputData, offset, priceX96)
                echo &"priceX96:{priceX96.toString()}"

                var boundaryLower = Int24.fromHex("0x0")
                var boundaryLowerDecodeLen = decode(inputData, offset, boundaryLower)
                offset += boundaryLowerDecodeLen
                echo &"{boundaryLowerDecodeLen} boundaryLower:",boundaryLower

                
            writeFile("logs.json", $logs)
        except:
            echo getCurrentExceptionMsg()

    # var options = %*{"fromBlock":"latest"}
    # let s = await web3.subscribeForLogs(options, eventHandler ,errorHandler) 
    # await notifFut

    # proc handleSwap(sender: Address, recipient: Address, amount0: StInt[256],  amount1: StInt[256],  priceX96: Uint256, boundary: Int24){.raises: [Defect], gcsafe.}=
    #     try:
    #         echo &"sender:{sender} recipient:{recipient} amount0:{amount0} amount1:{amount1} priceX96:{priceX96}, boundary:{boundary}"
    #     except Exception as err:
    #         doAssert false, err.msg

    # let swapRouterHub = web3.contractSender(SwapRouterHub, swapRouterAddress)
    # let s = await swapRouterHub.subscribe(Swap, %*{"fromBlock": "latest"}, handleSwap, errorHandler) 
    # await notifFut

    proc handlePlaceMakerOrder(orderId: UInt256,recipient: Address, bundleId: Uint64, zero:Bool, boundaryLower: Int24, amount: StUint[128]) {.gcsafe, raises: [Defect].} =
        try:
            echo &"orderId:{orderId} recipient:{recipient} bundleId:{bundleId} zero:{zero} boundaryLower:{boundaryLower.toString()}, amount:{amount.toString()}"
        except Exception as err:
            doAssert false, err.msg
            
    let grid = web3.contractSender(Grid, gridAddress)
    let s = await grid.subscribe(PlaceMakerOrder, %*{"fromBlock": "latest"}, handlePlaceMakerOrder, errorHandler) 
    await notifFut
    await s.unsubscribe()
    await web3.close()

waitFor main()
