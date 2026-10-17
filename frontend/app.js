// Decentralized Event Ticketing - frontend logic (ethers.js v5)

const ABI = [
  "function createEvent(string name, string venue, uint256 date, uint256 ticketPrice, uint256 totalTickets) returns (uint256)",
  "function buyTicket(uint256 eventId) payable returns (uint256)",
  "function transferTicket(uint256 ticketId, address to)",
  "function validateTicket(uint256 ticketId)",
  "function cancelEvent(uint256 eventId)",
  "function getEvent(uint256) view returns (tuple(uint256 id, string name, string venue, uint256 date, uint256 ticketPrice, uint256 totalTickets, uint256 ticketsSold, address organizer, bool active))",
  "function getTicket(uint256) view returns (tuple(uint256 ticketId, uint256 eventId, address owner, bool used))",
  "function myTickets(address) view returns (uint256[])",
  "function totalEvents() view returns (uint256)",
  "function admin() view returns (address)",
  "event EventCreated(uint256 indexed eventId, string name, address indexed organizer)",
  "event TicketPurchased(uint256 indexed ticketId, uint256 indexed eventId, address indexed buyer)"
];

let provider, signer, contract, account;

const $ = (id) => document.getElementById(id);
const log = (msg) => {
  const el = $("log");
  const line = `[${new Date().toLocaleTimeString()}] ${msg}\n`;
  el.textContent = line + el.textContent;
};

async function connect() {
  if (!window.ethereum) { alert("MetaMask not detected"); return; }
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();
  account = await signer.getAddress();
  $("account").textContent = account.slice(0, 6) + "..." + account.slice(-4);
  log(`Connected: ${account}`);
}

function loadContract() {
  const addr = $("contractAddress").value.trim();
  if (!ethers.utils.isAddress(addr)) { alert("Invalid address"); return; }
  if (!signer) { alert("Connect wallet first"); return; }
  contract = new ethers.Contract(addr, ABI, signer);
  $("status").textContent = `Contract loaded at ${addr}`;
  log(`Contract loaded: ${addr}`);
  loadEvents();
}

async function createEvent() {
  try {
    const name = $("evName").value;
    const venue = $("evVenue").value;
    const dateStr = $("evDate").value;
    const price = $("evPrice").value;
    const total = $("evTotal").value;
    if (!name || !venue || !dateStr || !price || !total) { alert("Fill all fields"); return; }
    const dateUnix = Math.floor(new Date(dateStr).getTime() / 1000);
    const priceWei = ethers.utils.parseEther(price);
    log(`Creating event: ${name}...`);
    const tx = await contract.createEvent(name, venue, dateUnix, priceWei, total);
    log(`Tx sent: ${tx.hash}`);
    const rcpt = await tx.wait();
    log(`Event created in block ${rcpt.blockNumber}`);
    loadEvents();
  } catch (e) { log(`Error: ${e.reason || e.message}`); }
}

async function loadEvents() {
  if (!contract) return;
  const container = $("events");
  container.innerHTML = "";
  const total = await contract.totalEvents();
  if (total == 0) {
    container.innerHTML = '<div class="empty-state"><span class="empty-icon">✳</span><strong>No events listed yet.</strong><span>Be the first to create one below.</span></div>';
    return;
  }
  for (let i = 1; i <= total; i++) {
    try {
      const ev = await contract.getEvent(i);
      const date = new Date(ev.date.toNumber() * 1000);
      const priceEth = ethers.utils.formatEther(ev.ticketPrice);
      const soldOut = ev.ticketsSold.eq(ev.totalTickets);
      const badge = !ev.active
        ? '<span class="badge cancelled">cancelled</span>'
        : (soldOut ? '<span class="badge used">sold out</span>' : '<span class="badge active">on sale</span>');
      const div = document.createElement("div");
      div.className = "event-item";
      div.innerHTML = `
        <h3>#${ev.id} ${ev.name} ${badge}</h3>
        <div>📍 ${ev.venue} · 📅 ${date.toLocaleString()}</div>
        <div>💰 ${priceEth} ETH · 🎫 ${ev.ticketsSold}/${ev.totalTickets} sold</div>
        <div style="font-size:0.75rem;color:#94a3b8">Organizer: ${ev.organizer}</div>
        <button data-id="${ev.id}" class="buyBtn">Buy Ticket</button>
        <button data-id="${ev.id}" class="cancelBtn">Cancel (organizer)</button>
      `;
      container.appendChild(div);
    } catch (e) { /* skip */ }
  }
  container.querySelectorAll(".buyBtn").forEach(b => b.onclick = () => buyTicket(b.dataset.id));
  container.querySelectorAll(".cancelBtn").forEach(b => b.onclick = () => cancelEvent(b.dataset.id));
}

async function buyTicket(eventId) {
  try {
    const ev = await contract.getEvent(eventId);
    log(`Buying ticket for event #${eventId}...`);
    const tx = await contract.buyTicket(eventId, { value: ev.ticketPrice });
    log(`Tx sent: ${tx.hash}`);
    const rcpt = await tx.wait();
    log(`Ticket purchased in block ${rcpt.blockNumber}`);
    loadEvents();
    loadMyTickets();
  } catch (e) { log(`Error: ${e.reason || e.message}`); }
}

async function cancelEvent(eventId) {
  try {
    log(`Cancelling event #${eventId}...`);
    const tx = await contract.cancelEvent(eventId);
    await tx.wait();
    log(`Event #${eventId} cancelled`);
    loadEvents();
  } catch (e) { log(`Error: ${e.reason || e.message}`); }
}

async function loadMyTickets() {
  if (!contract || !account) return;
  const container = $("myTickets");
  container.innerHTML = "";
  const ids = await contract.myTickets(account);
  if (ids.length === 0) {
    container.innerHTML = '<div class="subtle-empty">No tickets in this wallet yet. Browse events to find your next one.</div>';
    return;
  }
  for (const id of ids) {
    const t = await contract.getTicket(id);
    const ev = await contract.getEvent(t.eventId);
    const div = document.createElement("div");
    div.className = "ticket-item";
    div.innerHTML = `
      🎫 Ticket #${t.ticketId} · Event: ${ev.name}
      ${t.used ? '<span class="badge used">used</span>' : '<span class="badge active">valid</span>'}
    `;
    container.appendChild(div);
  }
}

async function validateTicket() {
  try {
    const id = $("validateId").value;
    log(`Validating ticket #${id}...`);
    const tx = await contract.validateTicket(id);
    await tx.wait();
    log(`Ticket #${id} validated`);
  } catch (e) { log(`Error: ${e.reason || e.message}`); }
}

async function transferTicket() {
  try {
    const id = $("transferId").value;
    const to = $("transferTo").value;
    log(`Transferring ticket #${id} to ${to}...`);
    const tx = await contract.transferTicket(id, to);
    await tx.wait();
    log(`Transferred`);
    loadMyTickets();
  } catch (e) { log(`Error: ${e.reason || e.message}`); }
}

$("connectBtn").onclick = connect;
$("loadBtn").onclick = loadContract;
$("createBtn").onclick = createEvent;
$("refreshBtn").onclick = loadEvents;
$("myTicketsBtn").onclick = loadMyTickets;
$("validateBtn").onclick = validateTicket;
$("transferBtn").onclick = transferTicket;

if (window.ethereum) {
  window.ethereum.on("accountsChanged", () => location.reload());
  window.ethereum.on("chainChanged", () => location.reload());
}
