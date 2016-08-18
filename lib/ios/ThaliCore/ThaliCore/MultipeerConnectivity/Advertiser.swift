//
//  Thali CordovaPlugin
//  Advertiser.swift
//
//  Copyright (C) Microsoft. All rights reserved.
//  Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
//

import Foundation
import MultipeerConnectivity

final class Advertiser: NSObject {
    private let advertiser: MCNearbyServiceAdvertiser

    let peerIdentifier: PeerIdentifier
    let serviceType: String
    let port: UInt16
    internal private(set) var isAdvertising: Bool = false
    private let receivedInvitationHandler: (session: Session) -> Void

    required init(peerIdentifier: PeerIdentifier, serviceType: String, port: UInt16,
                  receivedInvitationHandler: (session: Session) -> Void) {
        advertiser = MCNearbyServiceAdvertiser(peer: peerIdentifier.mcPeer,
                                               discoveryInfo:nil, serviceType: serviceType)
        self.peerIdentifier = peerIdentifier
        self.serviceType = serviceType
        self.port = port
        self.receivedInvitationHandler = receivedInvitationHandler
        super.init()
        advertiser.delegate = self
    }

    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        isAdvertising = true
    }

    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
}

extension Advertiser: MCNearbyServiceAdvertiserDelegate {

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        let mcSession = MCSession(peer: advertiser.myPeerID, securityIdentity: nil, encryptionPreference: .None)
        let session = Session(session: mcSession, identifier: peerID.displayName)
        invitationHandler(true, mcSession)
        receivedInvitationHandler(session: session)
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        isAdvertising = false
        print("WARNING: server didNotStartAdvertisingPeer")
    }
}