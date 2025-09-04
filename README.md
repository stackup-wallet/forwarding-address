# Forwarding Address

A lightweight protocol for enabling attribution of onchain payments through deterministically generated addresses tied to a primary account.

## Background

Receiving payments onchain at scale is a challenge due to the lack of attribution. With a single wallet, it is not possible to link `N` incoming payments to their corresponding user unless you do one of the following:

1. Control the frontend with offchain authentication for end users to make their payments from.
2. Get users to submit their sending address to you ahead of their payment.

Both options offer a subpar UX for your users. Alternatively, you could generate `N` receiving accounts for each user but this quickly becomes an operational nightmare for your team.

**Forwarding addresses is a system for generating counterfactual addresses that can be assigned to each user and immutably tied to your primary account. Sent payments to a forwarding address can be permissionlessly triggered to always sweep to the linked account.**

## Deployments

```
TBA
```

## Usage

Before being able to run any command, you need to create a .env file and set your environment variables. You can follow the example in .env.example.

### Install dependencies

```shell
$ forge install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
