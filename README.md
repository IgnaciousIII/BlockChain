# Decentralized Event Ticketing DApp

A decentralized application for creating events and buying, transferring, and validating tickets on the Ethereum blockchain. Built with Solidity, HTML/CSS/JS, and Ethers.js with MetaMask integration.

## Problem Addressed

Traditional event ticketing suffers from fraud, scalping through counterfeit duplication, opaque pricing, and lack of secure peer-to-peer resale. This DApp solves these by:
- Issuing each ticket on-chain with a unique immutable ID.
- Making ownership and transfers publicly verifiable.
- Allowing only the event organizer to validate tickets at entry.
- Paying organizers directly, with no intermediary.

## Project Structure

```
EventTicketingDApp/
├── contracts/
│   └── EventTicketing.sol        # Smart contract
├── frontend/
│   ├── index.html                # UI
│   ├── style.css                 # Styling
│   └── app.js                    # Ethers.js + MetaMask logic
├── tests/
│   └── EventTicketing_test.sol   # Remix unit tests
├── screenshots/                  # Evidence (compile, deploy, tx, UI)
└── README.md
```

## Smart Contract Overview

**File:** `contracts/EventTicketing.sol`

Key components:
- **Variables:** `admin`, `events` mapping, `tickets` mapping, `ticketsOf` per-address lists, counters.
- **Constructor:** sets `admin` to the deployer.
- **Functions:** `createEvent`, `buyTicket` (payable), `transferTicket`, `validateTicket`, `cancelEvent`, plus `getEvent`, `getTicket`, `myTickets`, `totalEvents` read helpers.
- **Validation / Modifiers:** `onlyAdmin`, `onlyOrganizer`, plus `require` checks for empty strings, past dates, zero tickets, sold-out events, payment amount, ownership, and used tickets.
- **Events:** `EventCreated`, `TicketPurchased`, `TicketTransferred`, `TicketValidated`, `EventCancelled`.

## How to Run

### 1. Compile and deploy the contract (Remix IDE)
1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new file `EventTicketing.sol` and paste `contracts/EventTicketing.sol`.
3. In the **Solidity Compiler** tab, select compiler **0.8.20** and click **Compile**.
4. In the **Deploy & Run Transactions** tab:
   - **Environment:** choose *Injected Provider – MetaMask* (for testnet) or *Dev - Ganache Provider* (for local).
   - Click **Deploy** and confirm in MetaMask / Ganache.
5. Copy the deployed contract address.

### 2. Connect MetaMask
1. Install the [MetaMask](https://metamask.io/) browser extension.
2. Add either:
   - **Ganache local network** (RPC URL: `http://127.0.0.1:7545`, Chain ID: `1337`), or
   - **Sepolia testnet** (fund with the [Sepolia faucet](https://sepoliafaucet.com/)).
3. Import a Ganache account (private key from Ganache UI) or use your testnet wallet.

### 3. Run the frontend
```bash
cd frontend
python3 -m http.server 8000
```
Open `http://localhost:8000` in a browser with MetaMask installed.
1. Click **Connect MetaMask** and approve.
2. Paste the deployed contract address and click **Load Contract**.
3. Create events, buy tickets, transfer, and validate.

## Deployment Details

- **Network used:** Ganache (local, Network ID 5777, Chain ID 1337, RPC `http://127.0.0.1:7545`)
- **Deployed contract address:** `0xa4758cc3D24b06E184930f44b47c80A5E0798D61`
- **Deployment transaction hash:** `0x7a5c269af73a185847ae7ec57c927c655c45f45d1fc9e0713a814c45ce0dcfa8`
- **Deployer / Admin address:** `0xBe9D37e7B7Ef02B4F16A618F1D356d0e5e7D2787`
- **Gas used (deployment):** 2,562,428
- **Compiler version:** Solidity 0.8.20 (EVM target: `paris`)

## Test Cases

| # | Scenario | Input | Expected | Observed |
|---|----------|-------|----------|----------|
| 1 | Valid event creation | future date, price 0.01 ETH, 100 tickets | Event created, id = 1 | ✅ Passed |
| 2 | Valid ticket purchase | eventId=1, msg.value = 0.01 ETH | Ticket issued, organizer paid | ✅ Passed |
| 3 | Valid ticket transfer | owned ticket → another address | Ownership moves | ✅ Passed |
| 4 | Valid ticket validation (organizer) | organizer validates owned event's ticket | `used = true` | ✅ Passed |
| 5 | Invalid: event in the past | date = `block.timestamp - 1` | Revert: "Date must be future" | ✅ Reverted |
| 6 | Invalid: zero tickets | totalTickets = 0 | Revert: "Tickets must be > 0" | ✅ Reverted |
| 7 | Invalid: underpayment | msg.value < ticketPrice | Revert: "Insufficient payment" | ✅ Reverted |
| 8 | Invalid: buy after cancel | event cancelled first | Revert: "Event cancelled" | ✅ Reverted |
| 9 | Unauthorised: non-organizer validates | different account calls `validateTicket` | Revert: "Only event organizer" | ✅ Reverted |
| 10 | Unauthorised: transfer not-owned ticket | caller != owner | Revert: "Not ticket owner" | ✅ Reverted |
| 11 | Unauthorised: cancel foreign event | different account calls `cancelEvent` | Revert: "Only event organizer" | ✅ Reverted |
| 12 | Read: `totalEvents` | after creating N events | returns N | ✅ Passed |

### Remix tests
`tests/EventTicketing_test.sol` can be run from Remix's **Solidity Unit Testing** plugin.

## Screenshots

In `screenshots/`:
- `01_compile.png` – Remix Solidity Compiler, EventTicketing.sol compiled successfully
- `02_metamask_deploy_prompt.png` – MetaMask "Deploy a contract" request on Ganache
- `03_deployed_contract.png` – Deployed contract live in Remix with callable functions
- `04_tx_success.png` – MetaMask "Confirmed" status for the deployment tx
- `05_ganache_deploy.png` – Ganache transaction receipt (hash, created contract address, gas used)
- `06_tx_failed.png` – Remix "Gas estimation failed" dialog for an invalid call (validateTicket on a non-existent ticket)
- `07_tx_failed_terminal.png` – Remix terminal output showing the reverted transaction
- `08_frontend_create_event.png` – Frontend DApp with wallet connected and createEvent request pending in MetaMask
- `09_frontend_event_listed.png` – Created event rendered in the "Available Events" list
- `10_frontend_buy_ticket.png` – buyTicket transaction request from the DApp
- `11_frontend_ticket_owned.png` – Event showing "1/100 sold" and the purchased ticket under "My Tickets"
- `12_ganache_tx_history.png` – Ganache Transactions tab listing all contract calls to the deployed address

## Security Notes

- No private keys, seed phrases, or mnemonics are included in this repository.
- Use a fresh test-only MetaMask account when deploying.

## Author

Sarvesh Kumar · Reg No. 230905212 · *Blockchain Technology (CSE4444) – Assignment 2*
