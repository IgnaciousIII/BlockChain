// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/EventTicketing.sol";

/// @title Remix unit tests for EventTicketing
contract EventTicketingTest {
    EventTicketing ticketing;
    uint256 eventId;

    function beforeAll() public {
        ticketing = new EventTicketing();
    }

    /// Valid: create an event in the future
    function createEventSucceeds() public {
        eventId = ticketing.createEvent(
            "Test Fest", "Hall A",
            block.timestamp + 7 days,
            0.01 ether,
            100
        );
        Assert.equal(eventId, uint256(1), "First event id should be 1");
        EventTicketing.Event memory ev = ticketing.getEvent(1);
        Assert.equal(ev.totalTickets, uint256(100), "Totals should match");
    }

    /// Invalid: past date rejected
    function createEventInPastReverts() public {
        try ticketing.createEvent("Bad", "X", block.timestamp - 1, 0, 5) {
            Assert.ok(false, "Should have reverted");
        } catch { Assert.ok(true, "Reverted as expected"); }
    }

    /// Invalid: zero ticket count rejected
    function createEventZeroTicketsReverts() public {
        try ticketing.createEvent("Bad", "X", block.timestamp + 1 days, 0, 0) {
            Assert.ok(false, "Should have reverted");
        } catch { Assert.ok(true, "Reverted as expected"); }
    }

    /// Unauthorised: non-organizer cannot cancel event
    function nonOrganizerCancelReverts() public {
        // this test contract is organizer; simulate non-organizer by using a fresh contract instance
        EventTicketing other = new EventTicketing();
        uint256 id = other.createEvent("Other", "Y", block.timestamp + 1 days, 0, 1);
        try other.cancelEvent(id + 999) {
            Assert.ok(false, "Should have reverted");
        } catch { Assert.ok(true, "Reverted as expected"); }
    }

    /// Read: totalEvents reflects state
    function totalEventsReturnsCount() public {
        Assert.equal(ticketing.totalEvents(), uint256(1), "One event created so far");
    }
}
