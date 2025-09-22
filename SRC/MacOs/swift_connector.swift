//Do I need this?
//import Cocoa
import NetworkExtension

@_cdecl("startVPN")
public func startVPN(_ config: UnsafePointer<Int8>, _ server: UnsafePointer<Int8>, _ result: UnsafeMutablePointer<Bool>) {
    let configString = String(cString: config)
    let serverAddress = String(cString: server)
        
    // Create a semaphore to wait for the async operation
    let semaphore = DispatchSemaphore(value: 0)
    
    VPNManager.startVPNTunnel(with: configString, serverAddress: serverAddress) { success in
        if success {
            print("VPN tunnel started successfully")
//            NSLog("Will turn off in 20 seconds")
            result.pointee = true
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(20)) { [] in
//                VPNManager.stopVPNTunnel()
//            }
        } else {
            print("Failed to start VPN tunnel")
            result.pointee = false
        }
        semaphore.signal()
    }
    
    semaphore.wait()
}

@_cdecl("stopVPN")
public func stopVPN() {
    VPNManager.stopVPNTunnel()
}

class VPNManager {
    private static var shared: VPNManager?
    private let delegate: AppDelegate
    
    private init() {
        self.delegate = AppDelegate()
    }
    
    static func startVPNTunnel(with config: String, serverAddress: String, completion: @escaping (Bool) -> Void) {
        if shared == nil {
            shared = VPNManager()
        }
        shared?.delegate.turnOnTunnel(with: config, serverAddress: serverAddress, completionHandler: completion)
    }
    
    static func stopVPNTunnel() {
        if shared == nil {
            shared = VPNManager()
        }
        shared?.delegate.turnOffTunnel()
    }
}

class AppDelegate: NSObject {
    func turnOnTunnel(with wgQuickConfig: String, serverAddress: String, completionHandler: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                completionHandler(false)
                return
            }
            
            let preExistingTunnelManager = tunnelManagersInSettings?.first
            let tunnelManager = preExistingTunnelManager ?? NETunnelProviderManager()
            
            let protocolConfiguration = NETunnelProviderProtocol()
            
            protocolConfiguration.providerBundleIdentifier = "com.raccoonline.vpnnet.PacketTunnel"
            protocolConfiguration.serverAddress = serverAddress
            
//            let wgQuickConfig = "[Interface]\nPrivateKey = OB1vABebl4pgS168s9KoonUgT32MAzXSfKZrDoAx+Vg=\nAddress = 10.200.180.2/24\nDNS = 1.1.1.1\n\n[Peer]\nPublicKey = Rjx4LjNhZNrK+l7XcWZFNRCp/yHy95OYdPz1Y97XCxA=\nAllowedIPs = 0.0.0.0/0,::/128\nEndpoint = 51.77.210.147:51820\nPersistentKeepalive = 21"
            
            protocolConfiguration.providerConfiguration = [
                "wgQuickConfig": wgQuickConfig
            ]
            
            tunnelManager.protocolConfiguration = protocolConfiguration
            tunnelManager.localizedDescription = "Raccoon VPN"
            tunnelManager.isEnabled = true
            
            tunnelManager.saveToPreferences { error in
                if let error = error {
                    NSLog("Error (saveToPreferences): \(error)")
                    completionHandler(false)
                    return
                }
                
                NETunnelProviderManager.loadAllFromPreferences { managers, loadError in
                    if let loadError = loadError {
                        NSLog("Error (loadAllFromPreferences): \(loadError)")
                        completionHandler(false)
                        return
                    }
                    
                    guard let loadedManager = managers?.first else {
                        NSLog("No VPN configurations found after saving")
                        completionHandler(false)
                        return
                    }

                    do {
                        NSLog("Starting the tunnel after reloading preferences")
                        guard let session = loadedManager.connection as? NETunnelProviderSession else {
                            fatalError("loadedManager.connection is invalid")
                        }
                        let activationAttemptId = UUID().uuidString
                        try session.startTunnel(options: ["activationAttemptId": activationAttemptId])
                        NSLog("Tunnel status: \(loadedManager.connection.status.rawValue)")
                    } catch {
                        NSLog("Error (startTunnel): \(error)")
                        completionHandler(false)
                    }
                    
                    completionHandler(true)
                }
            }
        }
    }
    
    func turnOffTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                return
            }
            NSLog("turnOffTunnel...")
            if let tunnelManager = tunnelManagersInSettings?.first {
                guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                    fatalError("tunnelManager.connection is invalid")
                }
                switch session.status {
                case .connected, .connecting, .reasserting:
                    NSLog("Stopping the tunnel")
                    session.stopTunnel()
                default:
                    NSLog("Stopping the tunnel (already stopped): \(session.status)")
                    break
                }
                
//                tunnelManager.removeFromPreferences { error in
//                    if let error = error {
//                        NSLog("Error (removeFromPreferences): \(error)")
//                        return
//                    }
//                    else {
//                        NSLog("Tunnel removed from preferences")
//                    }
//                }
            }
        }
    }
}
