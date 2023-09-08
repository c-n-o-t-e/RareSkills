`echidna . --contract EchidnaTest --config config.yaml`

[2023-09-08 10:18:39.62] Compiling .... Done! (12.205949s)
Analyzing contract: /Users/macbook/Documents/Blockchain/Rare/RareSkills/hardhat/contracts/EchidnaTest.sol:EchidnaTest
[2023-09-08 10:18:51.91] Running slither on .... Done! (1.279226s)
Loaded 2 transaction sequences from corpus/reproducers
Loaded 5 transaction sequences from corpus/coverage
dex(): passing
balance(): failed!💥  
 Call sequence, shrinking 665/5000:
balance()
balance()

Event sequence:
Panic(1): Using assert
Transfer(24) from: 0x62d69f6867a0a084c6d313943dc22023bc263691
Approval(30) from: 0xee35211c4d9126d520bbfeaf3cfee5fe7b86f221
Approval(0) from: 0xee35211c4d9126d520bbfeaf3cfee5fe7b86f221
Transfer(30) from: 0xee35211c4d9126d520bbfeaf3cfee5fe7b86f221
Transfer(30) from: 0xee35211c4d9126d520bbfeaf3cfee5fe7b86f221
Approval(41) from: 0x62d69f6867a0a084c6d313943dc22023bc263691
Approval(0) from: 0x62d69f6867a0a084c6d313943dc22023bc263691
Transfer(41) from: 0x62d69f6867a0a084c6d313943dc22023bc263691

token1(): passing
token(): passing
AssertionFailed(..): passing

Unique instructions: 3430
Unique codehashes: 3
Corpus size: 5
Seed: 7074996513801270538
