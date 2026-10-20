import Foundation
import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let proxyHost = "103.238.234.204"
    private let proxyPort = 8080

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[ProxyBytes] Starting Packet Tunnel -> \(proxyHost):\(proxyPort)")

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1280

        let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [
            NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "0.0.0.0")
        ]
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0")
        ]
        settings.ipv4Settings = ipv4Settings

        let proxySettings = NEProxySettings()
        proxySettings.httpServer = NEProxyServer(address: proxyHost, port: proxyPort)
        proxySettings.httpsServer = NEProxyServer(address: proxyHost, port: proxyPort)
        proxySettings.autoProxyConfigurationEnabled = false
        proxySettings.httpEnabled = true
        proxySettings.httpsEnabled = true
        proxySettings.excludeSimpleHostnames = false
        proxySettings.exceptionList = []
        settings.proxySettings = proxySettings

        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings

        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                NSLog("[ProxyBytes] Failed to apply network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            NSLog("[ProxyBytes] Tunnel activated")
            completionHandler(nil)
            self?.readPacketsContinuously()
        }
    }

    private func readPacketsContinuously() {
        packetFlow.readPackets { [weak self] _, _ in
            self?.readPacketsContinuously()
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[ProxyBytes] Stopping tunnel: \(reason.rawValue)")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let command = String(data: messageData, encoding: .utf8), command == "PING" {
            completionHandler?("PONG".data(using: .utf8))
            return
        }
        completionHandler?(nil)
    }
}
