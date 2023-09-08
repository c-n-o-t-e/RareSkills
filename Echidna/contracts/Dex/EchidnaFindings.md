`echidna . --contract EchidnaDexTest --config config.yaml`

```
[2023-09-08 11:07:01.08] Compiling .... Done! (15.681266s)
Analyzing contract: /Users/macbook/Documents/Blockchain/Rare/RareSkills/Echidna/contracts/Dex/EchidnaDexTest.sol:EchidnaDexTest
[2023-09-08 11:07:16.85] Running slither on .... Done! (1.574783s)
Loaded 1 transaction sequences from corpus/reproducers
Loaded 2 transaction sequences from corpus/coverage
dex(): passing
balance(): failed!💥
  Call sequence, shrinking 93/5000:
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


Unique instructions: 3293
Unique codehashes: 3
Corpus size: 1
Seed: 455721731518842075
```
