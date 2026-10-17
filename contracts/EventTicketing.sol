// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Decentralized Event Ticketing
/// @notice Organizer creates events; users buy, transfer, and get tickets validated at entry.
contract EventTicketing {
    struct Event {
        uint256 id;
        string name;
        string venue;
        uint256 date;           // unix timestamp
        uint256 ticketPrice;    // in wei
        uint256 totalTickets;
        uint256 ticketsSold;
        address organizer;
        bool active;
    }

    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address owner;
        bool used;
    }

    address public immutable admin;
    uint256 private nextEventId = 1;
    uint256 private nextTicketId = 1;

    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256[]) private ticketsOf;

    event EventCreated(uint256 indexed eventId, string name, address indexed organizer);
    event TicketPurchased(uint256 indexed ticketId, uint256 indexed eventId, address indexed buyer);
    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to);
    event TicketValidated(uint256 indexed ticketId, uint256 indexed eventId);
    event EventCancelled(uint256 indexed eventId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyOrganizer(uint256 eventId) {
        require(events[eventId].organizer == msg.sender, "Only event organizer");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Create a new event listing.
    function createEvent(
        string calldata name,
        string calldata venue,
        uint256 date,
        uint256 ticketPrice,
        uint256 totalTickets
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Name required");
        require(bytes(venue).length > 0, "Venue required");
        require(date > block.timestamp, "Date must be future");
        require(totalTickets > 0, "Tickets must be > 0");

        uint256 eventId = nextEventId++;
        events[eventId] = Event({
            id: eventId,
            name: name,
            venue: venue,
            date: date,
            ticketPrice: ticketPrice,
            totalTickets: totalTickets,
            ticketsSold: 0,
            organizer: msg.sender,
            active: true
        });

        emit EventCreated(eventId, name, msg.sender);
        return eventId;
    }

    /// @notice Buy a ticket to an active event. Pays organizer directly, refunds excess.
    function buyTicket(uint256 eventId) external payable returns (uint256) {
        Event storage ev = events[eventId];
        require(ev.id != 0, "Event does not exist");
        require(ev.active, "Event cancelled");
        require(block.timestamp < ev.date, "Event has passed");
        require(ev.ticketsSold < ev.totalTickets, "Sold out");
        require(msg.value >= ev.ticketPrice, "Insufficient payment");

        uint256 ticketId = nextTicketId++;
        tickets[ticketId] = Ticket({
            ticketId: ticketId,
            eventId: eventId,
            owner: msg.sender,
            used: false
        });
        ticketsOf[msg.sender].push(ticketId);
        ev.ticketsSold += 1;

        // Pay organizer, refund any excess
        (bool paid, ) = ev.organizer.call{value: ev.ticketPrice}("");
        require(paid, "Payment to organizer failed");
        uint256 excess = msg.value - ev.ticketPrice;
        if (excess > 0) {
            (bool refunded, ) = msg.sender.call{value: excess}("");
            require(refunded, "Refund failed");
        }

        emit TicketPurchased(ticketId, eventId, msg.sender);
        return ticketId;
    }

    /// @notice Transfer a ticket you own to another address.
    function transferTicket(uint256 ticketId, address to) external {
        Ticket storage t = tickets[ticketId];
        require(t.ticketId != 0, "Ticket does not exist");
        require(t.owner == msg.sender, "Not ticket owner");
        require(to != address(0), "Invalid recipient");
        require(!t.used, "Ticket already used");

        _removeFromOwner(msg.sender, ticketId);
        t.owner = to;
        ticketsOf[to].push(ticketId);

        emit TicketTransferred(ticketId, msg.sender, to);
    }

    /// @notice Organizer validates (marks used) a ticket at the entrance.
    function validateTicket(uint256 ticketId)
        external
        onlyOrganizer(tickets[ticketId].eventId)
    {
        Ticket storage t = tickets[ticketId];
        require(t.ticketId != 0, "Ticket does not exist");
        require(!t.used, "Already used");
        t.used = true;
        emit TicketValidated(ticketId, t.eventId);
    }

    /// @notice Organizer may cancel their event (before it starts).
    function cancelEvent(uint256 eventId) external onlyOrganizer(eventId) {
        Event storage ev = events[eventId];
        require(ev.active, "Already cancelled");
        require(block.timestamp < ev.date, "Event has passed");
        ev.active = false;
        emit EventCancelled(eventId);
    }

    // ---- read helpers ----

    function getEvent(uint256 eventId) external view returns (Event memory) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId];
    }

    function getTicket(uint256 ticketId) external view returns (Ticket memory) {
        require(tickets[ticketId].ticketId != 0, "Ticket does not exist");
        return tickets[ticketId];
    }

    function myTickets(address user) external view returns (uint256[] memory) {
        return ticketsOf[user];
    }

    function totalEvents() external view returns (uint256) {
        return nextEventId - 1;
    }

    function _removeFromOwner(address owner, uint256 ticketId) private {
        uint256[] storage list = ticketsOf[owner];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == ticketId) {
                list[i] = list[list.length - 1];
                list.pop();
                return;
            }
        }
    }
}
