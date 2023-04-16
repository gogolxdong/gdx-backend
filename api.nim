import std/[json, strformat, strutils]
import pkg/[chronos, presto, web3]

const
  uniswapV2PairAbi = """[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"uint256","name":"amount0In","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"amount1In","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"amount0Out","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"amount1Out","type":"uint256"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"Swap","type":"event"}]"""
  uniswapV2PairAddress = "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11" # Replace with the desired Uniswap V2 Pair address

type SwapInfo = object
    amount0In: int
    amount1In: int
    amount0Out: int
    amount1Out: int
    timestamp: int

var swapInfo: SwapInfo

proc handleSwapEvent(event: JsonNode) =
  swapInfo = SwapInfo(
    amount0In:parseInt(event["amount0In"].getStr),
    amount1In:parseInt(event["amount1In"].getStr),
    amount0Out:parseInt(event["amount0Out"].getStr), 
    amount1Out:parseInt(event["amount1Out"].getStr),
    timestamp:parseInt(event["timestamp"].getStr))

proc listenToSwapEvents() {.async.} =
  let
    w3 = newWeb3("https://mainnet.infura.io/v3/")
    contract = w3.getContract(uniswapV2PairAbi, uniswapV2PairAddress)

  var latestBlock = await w3.getBlockNumber()
  while true:
    let newBlock = await w3.getBlockNumber()
    if newBlock > latestBlock:
      echo "New block detected: ", newBlock
      let events = await contract.getPastEvents("Swap", latestBlock + 1, newBlock)
      for event in events:
        handleSwapEvent(event)
      latestBlock = newBlock

    await sleepAsync(5000)

proc handleRequest(request: Request): Future[ResponseData] {.async.} =
  let price = if swapInfo.amount1In == 0: 0.0 else: float(swapInfo.amount0In) / float(swapInfo.amount1In)
  return jsonResponse(%*{"price": price})

routes:
  get "/price":
    await handleRequest(request)

proc main() {.async.} =
  var server = newHttpServer(port = Port(8000))
  asyncCheck listenToSwapEvents()
  server.handle(get, "/price", getPriceHandler)
  await server.serve()

waitFor(main())
