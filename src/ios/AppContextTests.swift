//
//  Thali CordovaPlugin
//  AppContextTests.swift
//
//  Copyright (C) Microsoft. All rights reserved.
//  Licensed under the MIT license.
//  See LICENSE.txt file in the project root for full license information.
//

import XCTest
import UIKit
import ThaliCore

extension NetworkStatusParameters {

    static let allValues = [bluetooth, bluetoothLowEnergy, wifi, cellular, bssid]
}

struct Constants {

    struct TimeForWhich {

        static let  bluetoothStateIsChanged: NSTimeInterval = 10
    }

    struct NSNotificationName {

        static let centralBluetoothManagerDidChangeState = "CentralBluetoothManagerDidChangeState"
    }
}

private extension Selector {

    static let centralBluetoothManagerStateChanged =
        #selector(AppContextTests.centralBluetoothManagerStateChanged(_:))
}

enum BluetoothHardwareState: String {

    case on = "on"
    case off = "off"
}

// MARK: - Mock objects
class AppContextDelegateMock: NSObject, AppContextDelegate {
    /// Network status represented as JSON String.
    /// Gets updated value in didChangeNetworkStatus method.
    var networkStatus: String?

    /// Indicates that didChangeNetworkStatus method was called at least once.
    var networkStatusUpdated = false

    /// Bluetooth RadioState value represented as String
    /// Gets updated value in didChangeNetworkStatus method.
    var bluetoothStateActual: String?

    /// BluetoothLowEnergy RadioState value represented as String
    /// Gets updated value in didChangeNetworkStatus method.
    var bluetoothLowEnergyStateActual: String?

    /// WiFi RadioState value represented as String
    /// Gets updated value in didChangeNetworkStatus method.
    var wifiStateActual: String?

    /// Cellular RadioState value represented as String
    /// Gets updated value in didChangeNetworkStatus method.
    var cellularStateActual: String?

    var advertisingListeningState = ""

    var willEnterBackground = false
    var didEnterForeground = false
    var discoveryUpdated = false

    @objc func context(context: AppContext, didResolveMultiConnectWith paramsJSONString: String) {}
    @objc func context(context: AppContext,
                       didFailMultiConnectConnectionWith paramsJSONString: String) {}
    @objc func context(context: AppContext, didChangePeerAvailability peers: String) {}
    @objc func context(context: AppContext, didChangeNetworkStatus status: String) {
        networkStatusUpdated = true
        networkStatus = status

        bluetoothStateActual = nil
        bluetoothLowEnergyStateActual = nil
        wifiStateActual = nil
        cellularStateActual = nil

        if let dictinaryNetworkStatus = dictionaryValue(networkStatus!) {

            guard
                let bluetoothState =
                dictinaryNetworkStatus[NetworkStatusParameters.bluetooth.rawValue]
                    as? String
                else {
                    return
            }

            guard
                let bluetoothLowEnergyState =
                dictinaryNetworkStatus[NetworkStatusParameters.bluetoothLowEnergy.rawValue]
                    as? String
                else {
                    return
            }

            guard
                let wifiState =
                dictinaryNetworkStatus[NetworkStatusParameters.wifi.rawValue]
                    as? String
                else {
                    return
            }

            guard
                let cellularState =
                dictinaryNetworkStatus[NetworkStatusParameters.cellular.rawValue]
                    as? String
                else {
                    return
            }

            bluetoothStateActual = bluetoothState
            bluetoothLowEnergyStateActual = bluetoothLowEnergyState
            wifiStateActual = wifiState
            cellularStateActual = cellularState
        } else {
            XCTFail("Can not convert network status JSON string to dictionary")
        }
    }
    @objc func context(context: AppContext, didUpdateDiscoveryAdvertisingState
                       discoveryAdvertisingState: String) {
        advertisingListeningState = discoveryAdvertisingState
    }
    @objc func context(context: AppContext, didFailIncomingConnectionToPort port: UInt16) {}
    @objc func appWillEnterBackground(with context: AppContext) {
        willEnterBackground = true
    }
    @objc func appDidEnterForeground(with context: AppContext) {
        didEnterForeground = true
    }
}

// MARK: - Test cases
class AppContextTests: XCTestCase {

    var context: AppContext! = nil

    weak var expectationThatPrivateBluetoothStateIsChanged: XCTestExpectation?
    weak var expectationThatCoreBluetoothStateIsChanged: XCTestExpectation?
    weak var expectationThatBothBluetoothStatesAreChanged: XCTestExpectation?
    var bluetoothChangingStateGroup: dispatch_group_t?

    override func setUp() {
        context = AppContext(serviceType: "thaliTest")
    }

    override func tearDown() {
        context = nil
    }

    private func jsonDictionaryFrom(string: String) -> [String : AnyObject]? {
        guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        return (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as?
            [String : AnyObject]
    }

    // MARK: Tests

    private func validateAdvertisingUpdate(jsonString: String, advertising: Bool, browsing: Bool) {
        let json = jsonDictionaryFrom(jsonString)
        let listeningActive = (json?[JSONKey.discoveryActive.rawValue] as? Bool)
        let advertisingActive = (json?[JSONKey.advertisingActive.rawValue] as? Bool)
        print(advertisingActive)
        print(listeningActive)
        XCTAssertEqual(advertisingActive, advertising)
        XCTAssertEqual(listeningActive, browsing)
    }

    func testWillEnterBackground() {
        let delegateMock = AppContextDelegateMock()
        context.delegate = delegateMock
        NSNotificationCenter.defaultCenter()
                            .postNotificationName(UIApplicationWillResignActiveNotification,
                                                  object: nil)
        XCTAssertTrue(delegateMock.willEnterBackground)
    }

    func testDidEnterForeground() {
        let delegateMock = AppContextDelegateMock()
        context.delegate = delegateMock
        NSNotificationCenter.defaultCenter()
                            .postNotificationName(UIApplicationDidBecomeActiveNotification,
                                                  object: nil)
        XCTAssertTrue(delegateMock.didEnterForeground)
    }

    func testDidRegisterToNative() {
        var error: ErrorType?
        do {
            try context.didRegisterToNative(["test", "test"])
        } catch let err {
            error = err
        }
        XCTAssertNil(error)
        var contextError: AppContextError?
        do {
            let notAString = 42
            try context.didRegisterToNative([notAString])
        } catch let err as AppContextError {
            contextError = err
        } catch let error {
            XCTFail("unexpected error: \(error)")
        }
        XCTAssertEqual(contextError, .BadParameters)
    }

    func testGetIOSVersion() {
        XCTAssertEqual(NSProcessInfo().operatingSystemVersionString, context.getIOSVersion())
    }

    func testThaliCoreErrors() {
        // testing parameters count
        var error: AppContextError?
        do {
            try context.multiConnectToPeer([""])
        } catch let err as AppContextError {
            error = err
        } catch _ {}
        XCTAssertEqual(error, AppContextError.BadParameters)

        // testing parameter types
        error = nil
        do {
            try context.multiConnectToPeer([2, 2])
        } catch let err as AppContextError {
            error = err
        } catch _ {}
        XCTAssertEqual(error, AppContextError.BadParameters)
    }

    func testMultiConnect() {
        // todo will be implemented as soon as we will have the whole stack working #881
    }

    func testErrorDescription() {
        XCTAssertEqual(ThaliCoreError.IllegalPeerID.rawValue,
                       errorDescription(ThaliCoreError.IllegalPeerID))

        let unknownError = AppContextError.UnknownError
        XCTAssertEqual((unknownError as NSError).localizedDescription,
                       errorDescription(unknownError))
    }

    func testJsonValue() {
        var jsonDict: [String : AnyObject] = ["number" : 4.2]
        var jsonString = "{\"number\":4.2}"
        XCTAssertEqual(jsonValue(jsonDict), jsonString)
        jsonDict = ["string" : "42"]
        jsonString = "{\"string\":\"42\"}"
        XCTAssertEqual(jsonValue(jsonDict), jsonString)
        jsonDict = ["null" : NSNull()]
        jsonString = "{\"null\":null}"
        XCTAssertEqual(jsonValue(jsonDict), jsonString)
        jsonDict = ["bool" : true]
        jsonString = "{\"bool\":true}"
        XCTAssertEqual(jsonValue(jsonDict), jsonString)
    }

    func testListeningAdvertisingUpdateOnStartAdvertising() {
        let delegateMock = AppContextDelegateMock()
        context.delegate = delegateMock
        let port = 42
        let _ = try? context.startUpdateAdvertisingAndListening(withParameters: [port])
        validateAdvertisingUpdate(delegateMock.advertisingListeningState, advertising: true,
                                  browsing: false)
    }

    func testListeningAdvertisingUpdateOnStartListening() {
        let delegateMock = AppContextDelegateMock()
        context.delegate = delegateMock
        let _ = try? context.startListeningForAdvertisements()
        validateAdvertisingUpdate(delegateMock.advertisingListeningState, advertising: false,
                                  browsing: true)
    }

    func testPeerAvailabilityConversion() {
        let peerAvailability = PeerAvailability(peerIdentifier: PeerIdentifier(), available: true)
        let dictionaryValue = peerAvailability.dictionaryValue
        XCTAssertEqual(peerAvailability.peerIdentifier.uuid,
                       dictionaryValue[JSONKey.peerIdentifier.rawValue] as? String)
        XCTAssertEqual(peerAvailability.peerIdentifier.generation,
                       dictionaryValue[JSONKey.generation.rawValue] as? Int)
        XCTAssertEqual(peerAvailability.available,
                       dictionaryValue[JSONKey.peerAvailable.rawValue] as? Bool)
    }

    func testDisconnectErrors() {
        var contextError: AppContextError?
        do {
            let notAString = 42
            try context.disconnect([notAString])
        } catch let err as AppContextError {
            contextError = err
        } catch let error {
            XCTFail("unexpected error: \(error)")
        }
        XCTAssertEqual(contextError, .BadParameters)
    }

    // MARK: Private helpers
    @objc private func centralBluetoothManagerStateChanged(notification: NSNotification) {
        if notification.name == Constants.NSNotificationName.centralBluetoothManagerDidChangeState {
            expectationThatCoreBluetoothStateIsChanged?.fulfill()
            if let bluetoothChangingStateGroup = bluetoothChangingStateGroup {
                dispatch_group_leave(bluetoothChangingStateGroup)
            }
        }
    }

    private func changeBluetoothState(to state: BluetoothHardwareState,
                                         andWaitUntilChangesWithTimeout timeout: NSTimeInterval) {

        bluetoothChangingStateGroup = dispatch_group_create()

        expectationThatBothBluetoothStatesAreChanged =
            expectationWithDescription("Bluetooth is turned \(state.rawValue)")

        // When we're switching bluetooth hardware, we're waiting for two async acknowledgements.
        // The first one is from private API, the second acknowledgement is from CoreBluetooth.
        // This is why we enter the same group twice
        dispatch_group_enter(bluetoothChangingStateGroup!)
        dispatch_group_enter(bluetoothChangingStateGroup!)

        state == .on
            ? BluetoothHardwareControlManager.sharedInstance().turnBluetoothOn()
            : BluetoothHardwareControlManager.sharedInstance().turnBluetoothOff()

        dispatch_group_notify(
            bluetoothChangingStateGroup!,
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                self.privateAndPublicBluetoothStatesDidChanged()
            }
        )

        waitForExpectationsWithTimeout(Constants.TimeForWhich.bluetoothStateIsChanged) {
            error in
            XCTAssertNil(
                error,
                "Can not turn \(state.rawValue) Bluetooth hardware"
            )
        }

        bluetoothChangingStateGroup = nil
        expectationThatBothBluetoothStatesAreChanged = nil
    }

    private func privateAndPublicBluetoothStatesDidChanged() {
        expectationThatBothBluetoothStatesAreChanged?.fulfill()
    }
}

extension AppContextTests : BluetoothHardwareControlObserverProtocol {

    func receivedBluetoothManagerNotificationWithName(bluetoothNotificationName: String) {
        if bluetoothNotificationName == PowerChangedNotification {
            expectationThatPrivateBluetoothStateIsChanged?.fulfill()
            if let bluetoothChangingStateGroup = bluetoothChangingStateGroup {
                dispatch_group_leave(bluetoothChangingStateGroup)
            }
        }
    }
}
