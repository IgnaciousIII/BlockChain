# Deployment Details

## Environment
- **IDE:** Remix IDE 2.6.7 (https://remix.ethereum.org)
- **Compiler:** Solidity 0.8.20, EVM target `paris` (so Ganache's EVM accepts the bytecode — the default `shanghai` target emits `PUSH0`, which the Ganache GUI's EVM does not recognise)
- **Wallet:** MetaMask (Browser Extension), Imported Account `0xBe9D37e7B7Ef02B4F16A618F1D356d0e5e7D2787`
- **Network:** Ganache (local), Network ID `5777`, Chain ID `1337`, RPC `http://127.0.0.1:7545`
- **Workspace:** FLUFFY-THRONE (Ganache quickstart)

## Deployment Steps Performed
1. Loaded `contracts/EventTicketing.sol` into Remix.
2. In **Solidity Compiler** → Advanced Configurations → EVM Version set to `paris`.
3. Compiled with Solidity 0.8.20.
4. In **Deploy & Run** → Environment: *Injected Provider – MetaMask* (connected to the Ganache network).
5. Clicked **Deploy** (no constructor arguments) → confirmed in MetaMask.
6. Deployment confirmed on Ganache; address and tx hash copied below.

## Deployed Contract
- **Contract address:** `0xa4758cc3D24b06E184930f44b47c80A5E0798D61`
- **Deployer / Admin:** `0xBe9D37e7B7Ef02B4F16A618F1D356d0e5e7D2787`
- **Transaction hash:** `0x7a5c269af73a185847ae7ec57c927c655c45f45d1fc9e0713a814c45ce0dcfa8`
- **Gas used:** 2,562,428
- **Status:** CONTRACT CREATION – Confirmed

## Post-Deployment Interactions (evidence in `screenshots/`)
- `createEvent("Blockchain Summit 2026", "Manipal", 2026-10-26 17:00, 0.01 ETH, 100)` – success
- `buyTicket(1)` with `value = 0.01 ETH` – success, Ticket #1 issued
- `validateTicket(999)` – reverted with `"Ticket does not exist"` (invalid input case)
