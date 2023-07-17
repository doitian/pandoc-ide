---
author: ian@cryptape.com
date: 2023-07-17
---
# CKB Tx Builder Survey

## Synopsis

This survey covers SDK interfaces for constructing CKB transactions and includes a case study on txforge, a Bitcoin transaction builder. The txforge interfaces may inform the development of a more effective transaction builder interface for CKB.

## Provoking Questions

- 对于 tx builder 接口有什么改进建议？有没有参考项目推荐？
- 目前 SDKs 只对 system scripts 和某些我们挑选的 scripts 作了封装，对于其它 scripts 则缺少支持，也没法去全部支持，那如何才能简化应用间的交互呢？
- 目前我们 SDKs 走的多语言路线，那是不是 dApps 想被集成，也得维护多语言的 SDK 呢？
- 我的想法是需要有一个语言无关的关于交易构建的标准，这样只需要输入一些参数就能创建出一个其它 dApp 的合法交易出来。对于这样的标准，有没有什么想法？
- 除开交易构建标准，有其它的办法能解决 Scripts 互操作的问题吗？

> - Do you have any suggestions for improving the tx builder interface? Do you have any recommended reference projects?
> - Currently, the SDKs only encapsulate system scripts and some scripts we have selected, while lacking support for other scripts. It is not feasible to support all scripts. So, how can we simplify the interaction between dApps?
> - Currently, our SDK follows a multi-language route. Does that mean dApps developers who want to be integrated also need to maintain SDKs for multiple languages?
> - My idea is that there needs to be a language-independent standard for transaction construction, so that a legitimate transaction for another dApp can be created by simply entering some parameters. Do you have any thoughts on such a standard?
> - Aside from the transaction construction standard, are there any other ways to solve the problem of script interoperability?

## Lumos

[Lumos][] is a TypeScript/JavaScript SDK for CKB. The documentation of the package `@ckb-lumos/common-scripts` shows [the usage](https://lumos-website-git-stable-magickbase.vercel.app/api/modules/common_scripts.html#ckb-lumoscommon-scripts) to build a transaction:

[lumos]: https://github.com/ckb-js/lumos

```javascript
let txSkeleton = TransactionSkeleton({ cellProvider: indexer })

txSkeleton = await common.transfer(
  txSkeleton,
  fromInfos,
  "ckb1qyqrdsefa43s6m882pcj53m4gdnj4k440axqdt9rtd",
  BigInt(3500 * 10 ** 8),
  tipHeader,
)

// When you want to pay fee for transaction, just call `payFee`.
txSkeleton = await common.payFee(
  txSkeleton,
  fromInfos,
  BigInt(1*10**8),
  tipHeader,
)

txSkeleton = await common.prepareSigningEntries(
  txSkeleton
)

// Then you can sign messages in order and get contents.
// NOTE: lumos not provided tools for generate signatures now.
// Call `sealTransaction` to get a transaction.
const tx = sealTransaction(txSkeleton, contents)
```

To build a transaction, there are three steps to follow in Lumos.

1. Use a high level API like `common.transfer` to create the skeleton. Whenever the API needs an input, it uses a cell collector to find live cells. This is a common encapsulation used in all CKB SDKs.
2. Pay the fee and adjust the change output.
3. Sign/Seal the transaction. 

The `TransactionSkeleton` is a JavaScript object that utilizes ImmutableJS collections to store transaction entries. To add a manual input to the skeleton, use the code below.

```javascript
const inputCell = {...};
txSkeleton = txSkeleton.update("inputs", (inputs) => {
    return inputs.push(inputCell);
});
```

The definition of `TransactionSkeleton` can be found in the documentation for [Interface TransactionSkeletonInterface](https://lumos-website-git-stable-magickbase.vercel.app/api/interfaces/helpers.transactionskeletoninterface.html). This interface includes three fields that are not present in CKB transactions.

- `fixedEntries` flags frozen entries. For instance, the example below shows how to freeze the first input:
    ```javascript
    txSkeleton.update("fixedEntries", (entries) =>
      entries.push({field:"inputs", index: 0})
    )
    ```

- `signingEntries` contains digest messages for signing. The wallet can scan these entries and sign the provided digest messages using private keys.
- `inputSinces` duplicates the `since` fields in inputs. I'm not sure of the intention, but I believe it helps to retain the original `since` value when the input is replaced.


I would like to address two issues.

1. Although the high-level APIs can be complex and demand several parameters, they often don't offer customization options for all use cases. My recommendation is to employ the Builder Pattern for refactoring, which is structured as follows:
    ```javascript
    const txSkeleton = await common.transfer()
      .from(fromInfos)
      .to(receipient)
      .amount(BigInt(3500 * 10 ** 8))
      .build(txSkeleton);
    ```
2. Implementing a custom lock script can be challenging due to the lack of documentation and exported helper functions. Nevertheless, to use Lumos' type scripts alongside a custom lock script, it's necessary to implement the latter. This is because the live cell collector and the signing process are intertwined. Lumos is only able to collect cells that it knows how to unlock.

## CKB Cli

[CKB-cli][ckb-cli] is a command line tool for CKB. It provides `tx` subcommand to construct CKB transactions incrementally. CKB-cli stores the intermediate results in a JSON file, which has following fields:

[ckb-cli]: https://github.com/nervosnetwork/ckb-cli

```rust
pub(crate) struct ReprTxHelper {
    pub(crate) transaction: json_types::Transaction,
    pub(crate) multisig_configs: HashMap<H160, ReprMultisigConfig>,
    pub(crate) signatures: HashMap<JsonBytes, Vec<JsonBytes>>,
}
```

The purpose of these fields is clear from their name: they are used for signing. However, `ckb-cli tx` has a restricted interface and does not allow manual inclusion of `cell_deps` and `header_deps`.

## Rust SDK

The [the Rust SDK][ckb-sdk-rust] contains a usage example to build a transaction manually in its README:

[ckb-sdk-rust]: https://github.com/nervosnetwork/ckb-sdk-rust

```rust
let balancer = CapacityBalancer::new_simple(sender.payload().into(), placeholder_witness, 1000);

let cell_dep_resolver = {
    let genesis_block = ckb_client.get_block_by_number(0.into()).unwrap().unwrap();
    DefaultCellDepResolver::from_genesis(&BlockView::from(genesis_block)).unwrap()
};
let header_dep_resolver = DefaultHeaderDepResolver::new(ckb_rpc);
let mut cell_collector = DefaultCellCollector::new(ckb_rpc);
let tx_dep_provider = DefaultTransactionDependencyProvider::new(ckb_rpc, 10);

// Build the transaction
let output = CellOutput::new_builder()
    .lock(Script::from(&receiver))
    .capacity(capacity.0.pack())
    .build();
let builder = CapacityTransferBuilder::new(vec![(output, Bytes::default())]);
let (_tx, _) = builder
    .build_unlocked(
        &mut cell_collector,
        &cell_dep_resolver,
        &header_dep_resolver,
        &tx_dep_provider,
        &balancer,
        &unlockers,
    )
    .unwrap();
```

The SDK splits the construction process into two stages: building and signing. It utilizes the CKB transaction structure to store intermediate results, so users must specify which script group to sign during the signing stage.

High-level APIs are organized as various [builders][ckb-sdk-rust-tx-builder]. However, like Lumos, theres builders are complex and would benefit from employing the Builder pattern.

[ckb-sdk-rust-tx-builder]: https://github.com/nervosnetwork/ckb-sdk-rust/tree/master/src/tx_builder

## Java SDK

Here's an example of using the [CKB SDK for Java][ckb-sdk-java] to construct a CKB transaction.

[ckb-sdk-java]: https://github.com/nervosnetwork/ckb-sdk-java

```java
String sender = "ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsq2qf8keemy2p5uu0g0gn8cd4ju23s5269qk8rg4r";
String receiver = "ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqg958atl2zdh8jn3ch8lc72nt0cf864ecqdxm9zf";
Iterator<TransactionInput> iterator = new InputIterator(sender);
TransactionWithScriptGroups txWithGroups = new CkbTransactionBuilder(iterator, Network.TESTNET)
    .addOutput(receiver, 50100000000L)
    .setFeeRate(1000)
    .setChangeOutput(sender)
    .build();
```

[TransactionWithScriptGroups](https://github.com/nervosnetwork/ckb-sdk-java/blob/f5129f179de65ea4e964082f0cfd4d55ab960f0e/core/src/main/java/org/nervos/ckb/sign/TransactionWithScriptGroups.java) format serves as the intermediate transaction format. This format includes an additional field to index script groups, facilitating signing.

The SDK offers [specific builders](https://github.com/nervosnetwork/ckb-sdk-java/blob/master/ckb/src/main/java/org/nervos/ckb/transaction/SudtTransactionBuilder.java) for different dApps. It solves the issue found in Lumos and Rust SDK, where high-level APIs require too many parameters.

## Go SDK

[The Go SDK][ckb-sdk-go] is similar to the Java SDK in that it only includes script groups in the intermediate transaction format and adopts the Builder pattern in high-level APIs such as [sudt](https://github.com/nervosnetwork/ckb-sdk-go/blob/v2/collector/builder/sudt.go).

[ckb-sdk-go]: https://github.com/nervosnetwork/ckb-sdk-go

```go
tx := &types.Transaction{
	Version: 0,
	CellDeps: []*types.CellDep{
		&types.CellDep{
			OutPoint: &types.OutPoint{
				TxHash: types.HexToHash("0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37"),
				Index:  0,
			},
			DepType: types.DepTypeDepGroup,
		},
	},
	HeaderDeps: nil,
	Inputs: []*types.CellInput{
		&types.CellInput{
			Since: 0,
			PreviousOutput: &types.OutPoint{
				TxHash: types.HexToHash("0x2ff7f46d509c85e1878cf091aef0ba0b89f34f9fea9e8bc868aed2d627490512"),
				Index:  1,
			},
		},
	},
	Outputs: []*types.CellOutput{
		&types.CellOutput{
			Capacity: 10000000000,
			Lock: &types.Script{
				CodeHash: types.HexToHash("0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8"),
				HashType: types.HashTypeType,
				Args:     common.FromHex("0x3f1573b44218d4c12a91919a58a863be415a2bc3"),
			},
			Type: nil,
		},
		&types.CellOutput{
			Capacity: 90000000000,
			Lock: &types.Script{
				CodeHash: types.HexToHash("0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8"),
				HashType: types.HashTypeType,
				Args:     common.FromHex("0xb1d41a1fb06f782cf10a87f3e49e80711af63fcf"),
			},
			Type: nil,
		},
	},
	OutputsData: make([][]byte, 2),
	Witnesses: [][]byte{
		common.FromHex("0x55000000100000005500000055000000410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),
	},
}

scriptGroups := []*transaction.ScriptGroup{
	&transaction.ScriptGroup{
		Script: types.Script{
			CodeHash: types.HexToHash("0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8"),
			HashType: types.HashTypeType,
			Args:     common.FromHex("0x3f1573b44218d4c12a91919a58a863be415a2bc3"),
		},
		GroupType:    transaction.ScriptTypeLock,
		InputIndices: []uint32{0},
	},
}
txWithScriptGroups := &transaction.TransactionWithScriptGroups{
	TxView:       tx,
	ScriptGroups: scriptGroups,
}
```

## Perun for CKB

Perun for CKB is a payment channel app built on CKB. The app has its own [transaction builder][perun-tx-builder] based on the Go SDK.

[perun-tx-builder]: https://github.com/perun-network/perun-ckb-backend/blob/dev/transaction/transaction.go

There are 5 steps to create a Perun transaction.

1. Index script groups.
2. Balance CKB and SUDT assets.
3. Handle dApp logic starting with outputs, then inputs.
4. Pay the fee.
5. Build and sign the transaction.

Perun follows an interesting pattern of building transactions where outputs are prepared first. This approach simplifies the transaction builder interface as most transaction fields can be derived backward from outputs. However, certain applications require inputs to be added before building outputs, such as incrementing a counter stored in a cell.

## TxForge

[TxForge](https://github.com/libitx/txforge) is a library to construct Bitcoin transaction.

```javascript
import { forgeTx, toUTXO, casts } from 'txforge'

// We'll use these Casts in our transaction
const { P2PKH, OpReturn } = casts

// You'll need UTXOs to fund a transaction. Use the `toUTXO` helper to turn
// your UTXO data into the required objects.
const utxo = toUTXO({
  txid,       // utxo transaction id
  vout,       // utxo output index
  satoshis,   // utxo amount
  script      // utxo lock script
})

// Forge a transaction
const tx = forgeTx({
  inputs: [
    P2PKH.unlock(utxo, { privkey: myPrivateKey })
  ],
  outputs: [
    P2PKH.lock(5000, { address: '1DBz6V6CmvjZTvfjvWpvvwuM1X7GkRmWEq' }),
    OpReturn.lock(0, { data: ['meta', '1DBz6V6CmvjZTvfjvWpvvwuM1X7GkRmWEq', txid] })
  ],
  change: { address: '1Nro9WkpaKm9axmcfPVp79dAJU1Gx7VmMZ' }
})

// And behold! Forged by the Gods and found by a King - a transaction is born.
console.log(tx.toHex())
```

TxForge introduces the concept [Casts](https://github.com/libitx/txforge/wiki/Understanding-Casts) for unlocking and signing. For users, Cases look like function calls to unlock inputs and lock outputs. Custom Casts can be created easily using the provided [guidelines](https://github.com/libitx/txforge/wiki/Creating-custom-Casts).

As signing logic is delegated to Casts, TxForge does not store signing information. It simply adds two extra fields.

1. `locktime`: Similar to the `since` fields in CKB.
2. `change`: For paying fee and creating the change output.

The difference between it and Lumos is that Lumos stores signing information in addition, while TxForge uses Casts to generate signatures.

## Conclusion

The survey shows a clear agreement on the steps to follow in creating a CKB transaction:

1. Utilize a high-level API to create the transaction skeleton.
2. Wrap the logic that finds live cells in Cell Collector.
3. Ensure transaction balance, handling the transaction fee and change output.
4. Generate digest messages and sign the transaction.

The high-level APIs are often quiet complex which deserve the Builder patterns like in the Java and Go SDKs.

The Cell Collector is crucial for simplifying the process of discovering live cells in dApps. Typically, this task is delegated to ckb-indexer or similar services. However, Lumos imposes additional requirements that it only collects cells for recognized lock scripts.

Perun employs a distinct method of constructing transactions, beginning with the outputs as opposed to the standard practice of starting with the inputs. This approach proves beneficial for dApps where the entire transaction can be deduced solely from the outputs, resulting in a simpler transaction builder.

The survey highlights an issue with the inconsistency of the interfaces in the SDKs. When switching to a new programming language, developers must learn from the ground up. Uniform interfaces also can simplify maintenance work loads, since we can use a meta language to describe the interfaces and generate code and documentations for different languages.

The complexity rises when dealing with script composition and integrating dApps that use different programming languages. DApp developers face the challenge of creating a valid transaction that involves lock and type scripts developed by others, as CKB lacks a standard for exchanging transaction construction interfaces among dApps. While SDKs can easily create transactions with system and Foundation-developed scripts, they offer limited support for other scripts. Although many dApp developers are willing to integrate their scripts into other dApps, maintaining dApp SDKs in multiple languages can be a burden for them.

I believe it's crucial to have a language-independent standard to describe how to build a transaction. Here I propose two potential solutions that could inspire innovative approaches.

1. Define a standard format for describing how transactions are constructed. SDKs can either parse and execute the construction instructions at runtime, or generate the code beforehand. Following is the example format in YAML:
    ```yaml
    steps:
    - uses: add-input
      with:
        txHash: ...
        index: 0
    - uses: collect-inputs
    - with:
        lockScript: ...
        where:
          ckb:
            gt: 100
    ```
2. Develop a transaction construction service and encourage developers to contribute custom modules for their dApps in the service. SDKs calls RPC methods of this service to build transactions. Since SDKs are already using external services such as ckb-indexer to create transactions, moving all of the transaction constructing logic to external services won't change the use of the SDK much.