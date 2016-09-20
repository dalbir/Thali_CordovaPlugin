//
//  Thali CordovaPlugin
//  SocketRelayTests.swift
//
//  Copyright (C) Microsoft. All rights reserved.
//  Licensed under the MIT license.
//  See LICENSE.txt file in the project root for full license information.
//

import XCTest
@testable import ThaliCore
import MultipeerConnectivity

class SocketRelayTests: XCTestCase {

    func testGetTimeoutErrorOnCreateSocket() {
        // Preconditions
        let createSocketTimeout: NSTimeInterval = 1.0
        let relay =
            SocketRelay<BrowserVirtualSocketBuilder>(createSocketTimeout: createSocketTimeout)
        let peerID = MCPeerID(displayName: NSUUID().UUIDString)
        let mcSession = MCSession(peer: peerID)
        let session = Session(session: mcSession, identifier: peerID,
                              disconnectHandler: unexpectedDisconnectHandler)
        var error: ThaliCoreError?
        let getTimeoutErrorOnCreateSocketExpectation =
            expectationWithDescription("get timeout error on create socket")

        relay.createSocket(with: session) { port, err in
            error = err as? ThaliCoreError
            getTimeoutErrorOnCreateSocketExpectation.fulfill()
        }

        // Should
        waitForExpectationsWithTimeout(createSocketTimeout, handler: nil)
        XCTAssertEqual(error, .ConnectionTimedOut)
    }

    func testReceiveVirtualSocketOnCreateSocket() {
        // Preconditions
        let foundPeerExpectation = expectationWithDescription("found peer")
        let peerIdentifier = PeerIdentifier()
        var browserStreams, advertiserStreams: (NSOutputStream, NSInputStream)?

        let (advertiser, browser) = createMPCFConnection(advertiserIdentifier: peerIdentifier,
                                                         advertiserSessionHandler: { session in
            let _ = AdvertiserVirtualSocketBuilder(session: session,
                completionHandler: { socket, error in
                advertiserStreams = socket
            })
        }) { [weak foundPeerExpectation] in
            foundPeerExpectation?.fulfill()
        }
        let foundPeerTimeout: NSTimeInterval = 2.0
        waitForExpectationsWithTimeout(foundPeerTimeout, handler: nil)

        do {
            let session = try browser.inviteToConnectPeer(with: peerIdentifier,
                    disconnectHandler: unexpectedDisconnectHandler)
            let socketCreatedExpectation = expectationWithDescription("socket created")
            let _ = BrowserVirtualSocketBuilder(session: session,
                    completionHandler: { [weak socketCreatedExpectation] socket, error in
                        browserStreams = socket
                        socketCreatedExpectation?.fulfill()
                    })
            let socketCreatedTimeout: NSTimeInterval = 5
            waitForExpectationsWithTimeout(socketCreatedTimeout, handler: nil)

            // Should
            XCTAssertNotNil(advertiser)
            XCTAssertNotNil(browserStreams)
            XCTAssertNotNil(advertiserStreams)
        } catch let error {
            XCTAssertNil(error)
        }
    }
}