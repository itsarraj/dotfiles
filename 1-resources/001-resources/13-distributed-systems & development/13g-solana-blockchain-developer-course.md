---
id: 20250730183455
title: Solana Blockchain Developer Course Setup Development Notes
date: 2025-07-30 18:34
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [solana, blockchain, web3, rust, development, course]
links: [https://solana.com/docs, https://explorer.solana.com/]
---
# Log
- 2025-07-30 18:34 - Created note.

# Notes

# Solana Setup and Development Notes

# Airdropping a solana in test
used solana web3 SDK for creating a airdrop test
npm i @solana/web3.js

# Creating my own cryptocurrency
https://github.com/LearnWithArjun/solana-env-setup/blob/main/mac_or_linux_setup.md

## 1. Installing Solana CLI
Installing the solana CLI with this and PATH will be set automatically
https://solana.com/docs/intro/installation#install-the-solana-cli
```bash
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
```

next I did this and it changed RPC url to localhost
solana config set --url localhost
solana config get

The main Solana RPC (Remote Procedure Call) endpoints for interacting with the Solana blockchain are: https://api.mainnet-beta.solana.com for mainnet, https://api.devnet.solana.com for devnet, and https://api.testnet.solana.com for testnet. These URLs allow developers to query the Solana blockchain, submit transactions, and access network information. 


› solana config get
Config File: /home/plutonium/.config/solana/cli/config.yml
RPC URL: https://api.mainnet-beta.solana.com
WebSocket URL: wss://api.mainnet-beta.solana.com/ (computed)
Keypair Path: /home/plutonium/.config/solana/id.json
Commitment: confirmed

› solana config set --url localhost
Config File: /home/plutonium/.config/solana/cli/config.yml
RPC URL: http://localhost:8899
WebSocket URL: ws://localhost:8900/ (computed)
Keypair Path: /home/plutonium/.config/solana/id.json
Commitment: confirmed

## 5. Anchor CLI Setup
cargo install --git https://github.com/solana-foundation/anchor avm --force

## 2. Keypair Generation and Wallet
solana-keygen new
```bash
› solana-keygen new
Generating a new keypair

For added security, enter a BIP39 passphrase

NOTE! This passphrase improves security of the recovery seed phrase NOT the
keypair file itself, which is stored as insecure plain text

BIP39 Passphrase (empty for none):

Wrote new keypair to /home/plutonium/.config/solana/id.json
=============================================================================
pubkey: 9k3zbwuzgqYvv5peZTPfLhxttNWedsy7yNxEDb3wxDuy
=============================================================================
Save this seed phrase and your BIP39 passphrase to recover your new keypair:
film gain forward obey volcano horror park venture fine access memory retreat
=============================================================================
```
solana-keygen pubkey
› solana-keygen pubkey
9k3zbwuzgqYvv5peZTPfLhxttNWedsy7yNxEDb3wxDuy
›

## setting the solana rfc devnet
https://solana.com/docs/references/clusters

solana config set --url https://api.devnet.solana.com

## airdropping ourself a solana 
› solana airdrop 2 9k3zbwuzgqYvv5peZTPfLhxttNWedsy7yNxEDb3wxDuy --url devnet
Requesting airdrop of 2 SOL

Signature: 3j8vQbi5kPFEZ8NnmntsCREz4jebqM5yspnScAT7jDQVomN9w5eSq6HXPUkJKgDDp4HEr9gZS5P98WFH55KshgDq

2 SOL

## can verify the devnet for this transactions
https://explorer.solana.com/address/9k3zbwuzgqYvv5peZTPfLhxttNWedsy7yNxEDb3wxDuy?cluster=devnet

## spl program 
## creating our own token spl library
Token are created using SPL programs and when they go on the blockchain they 
are given a unique address like `7SvdC3KYsi8u1oUihSkDNWb7F7JwPHwshxo5uRdgMDyx` 
This address will allow us to

› spl-token create-token --url devnet
Creating token 7SvdC3KYsi8u1oUihSkDNWb7F7JwPHwshxo5uRdgMDyx under program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA

Address:  7SvdC3KYsi8u1oUihSkDNWb7F7JwPHwshxo5uRdgMDyx
Decimals:  9

Signature: 4NKBCi9ghLqB1P5UaKo3X6Rt9eyhpYraB2iZwbQ6kGDXS2rH2rtLFkLBb1tciMCwfHASbz6ft21d6k8Dcag4guQP

## creating account with this token
› spl-token create-account 7SvdC3KYsi8u1oUihSkDNWb7F7JwPHwshxo5uRdgMDyx --url devnet
Creating account D6qPw7xDiYyJyLFsbPQrfV7viBZji4QSD1kPrCoSPdUj

Signature: 4ofShpUr8cr7ELkDbJExr9syUUv4VSQinTj8c5HEXbcaVLMAXqqCRZncUpYHaWcZd5SaANZUENk9ZZsA8b89JzBs

--
This ID `D6qPw7xDiYyJyLFsbPQrfV7viBZji4QSD1kPrCoSPdUj` here represents the 
address of a empty token account in our wallet.

## checking balance of this token
› spl-token balance 7SvdC3KYsi8u1oUihSkDNWb7F7JwPHwshxo5uRdgMDyx --url devnet
0

## 


