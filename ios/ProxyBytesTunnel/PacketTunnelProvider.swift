import Foundation
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // Server Host and Port hardcoded for instant 1-tap connection
    private let proxyHost = "103.238.234.204"
    private let proxyPort = 8080
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[ProxyBytes] >>> Starting Packet Tunnel to \(proxyHost):\(proxyPort)")
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyHost)
        
        // 1. Configure system-wide HTTP and HTTPS Proxy settings
        let proxySettings = NEProxySettings()
        proxySettings.httpServer = NEProxyServer(address: proxyHost, port: proxyPort)
        proxySettings.httpsServer = NEProxyServer(address: proxyHost, port: proxyPort)
        proxySettings.autoProxyConfigurationEnabled = false
        proxySettings.httpEnabled = true
        proxySettings.httpsEnabled = true
        proxySettings.excludeSimpleHostnames = false
        proxySettings.exceptionList = []
        settings.proxySettings = proxySettings
        
        // 2. Configure Virtual IP interface (required by iOS NetworkExtension)
        let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        // Route default traffic so DNS and connections flow through the tunnel
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // 3. DNS Servers
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8", "1.0.0.1"])
        settings.dnsSettings = dnsSettings
        
        // 4. Apply settings to active iOS NetworkExtension subsystem
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                NSLog("[ProxyBytes] [!] Failed to apply tunnel network settings: \(error.localizedDescription)")
                completionHandler(error)
            } else {
                NSLog("[ProxyBytes] [+] Tunnel successfully activated with Proxy \(self.proxyHost):\(self.proxyPort)")
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[ProxyBytes] >>> Stopping Packet Tunnel (reason: \(reason.rawValue))")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let command = String(data: messageData, encoding: .utf8), command == "PING" {
            let response = "PONG".data(using: .utf8)
            completionHandler?(response)
        } else {
            completionHandler?(nil)
        }
    }
}
