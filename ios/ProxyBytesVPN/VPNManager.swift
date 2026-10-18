import Foundation
import NetworkExtension
import Combine
import UIKit

enum VPNStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected: return "CHƯA KẾT NỐI"
        case .connecting: return "ĐANG KẾT NỐI..."
        case .connected: return "ĐÃ KẾT NỐI"
        case .disconnecting: return "ĐANG NGẮT..."
        case .error(let msg): return "LỖI: \(msg)"
        }
    }
}

class VPNManager: ObservableObject {
    static let shared = VPNManager()
    
    @Published var status: VPNStatus = .disconnected
    @Published var isConnected: Bool = false
    @Published var serverIP: String = "103.238.234.204"
    @Published var serverPort: Int = 8080
    @Published var latencyMs: Int? = nil
    @Published var logs: [String] = []
    
    private var manager: NETunnelProviderManager?
    private var timer: Timer?
    
    init() {
        log("Khởi tạo hệ thống ProxyBytes VPN...")
        loadAndCreateProviderManager()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        measureLatency()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.measureLatency()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.logs.insert("[\(timestamp)] \(message)", at: 0)
            if self.logs.count > 50 {
                self.logs.removeLast()
            }
        }
    }
    
    func loadAndCreateProviderManager(completion: (() -> Void)? = nil) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                self.log("Lỗi tải cấu hình hệ thống: \(error.localizedDescription)")
                completion?()
                return
            }
            
            let baseBundleId = Bundle.main.bundleIdentifier ?? "com.proxybytes.vpn"
            let tunnelId = "\(baseBundleId).tunnel"
            
            if let existing = managers?.first {
                self.manager = existing
                self.updateStatus(from: existing.connection.status)
                self.log("Đã tìm thấy cấu hình VPN có sẵn.")
                completion?()
            } else {
                self.log("Tạo cấu hình VPN mới...")
                let newManager = NETunnelProviderManager()
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = tunnelId
                proto.serverAddress = "\(self.serverIP):\(self.serverPort)"
                
                newManager.protocolConfiguration = proto
                newManager.localizedDescription = "ProxyBytes 103.238.234.204"
                newManager.isEnabled = true
                
                newManager.saveToPreferences { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        self.log("Lỗi lưu cấu hình: \(error.localizedDescription)")
                        completion?()
                    } else {
                        // Reload from preferences so the manager instance is attached to the system
                        NETunnelProviderManager.loadAllFromPreferences { [weak self] reloaded, _ in
                            self?.manager = reloaded?.first
                            self?.log("Đã lưu và đồng bộ cấu hình VPN hệ thống thành công!")
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    func toggle() {
        if isConnected {
            disconnect()
        } else {
            connect()
        }
    }
    
    func connect() {
        status = .connecting
        log("Đang bắt đầu kết nối tới \(serverIP):\(serverPort)...")
        
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.status = .error(error.localizedDescription)
                    self.log("Lỗi đọc cấu hình: \(error.localizedDescription)")
                }
                return
            }
            
            let targetManager = managers?.first ?? NETunnelProviderManager()
            let baseBundleId = Bundle.main.bundleIdentifier ?? "com.proxybytes.vpn"
            let tunnelId = "\(baseBundleId).tunnel"
            
            let proto = (targetManager.protocolConfiguration as? NETunnelProviderProtocol) ?? NETunnelProviderProtocol()
            proto.providerBundleIdentifier = tunnelId
            proto.serverAddress = "\(self.serverIP):\(self.serverPort)"
            
            targetManager.protocolConfiguration = proto
            targetManager.localizedDescription = "ProxyBytes 103.238.234.204"
            targetManager.isEnabled = true
            
            targetManager.saveToPreferences { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        self.status = .error(error.localizedDescription)
                        self.log("Lỗi lưu cấu hình: \(error.localizedDescription)")
                    }
                    return
                }
                
                // CRUCIAL: Reload preferences so system daemon registers the manager
                NETunnelProviderManager.loadAllFromPreferences { [weak self] reloadedManagers, error in
                    guard let self = self else { return }
                    guard let activeManager = reloadedManagers?.first else {
                        DispatchQueue.main.async {
                            self.status = .error("Không tìm thấy cấu hình sau khi lưu")
                            self.log("Lỗi: Không tìm thấy profile VPN")
                        }
                        return
                    }
                    
                    self.manager = activeManager
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        do {
                            try activeManager.connection.startVPNTunnel()
                            self.log("Đã gửi yêu cầu startVPNTunnel!")
                        } catch {
                            DispatchQueue.main.async {
                                self.status = .error(error.localizedDescription)
                                self.log("Không thể start tunnel: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func disconnect() {
        guard let manager = manager else { return }
        log("Đang ngắt kết nối VPN...")
        status = .disconnecting
        manager.connection.stopVPNTunnel()
    }
    
    @objc private func vpnStatusDidChange() {
        guard let manager = manager else { return }
        DispatchQueue.main.async {
            self.updateStatus(from: manager.connection.status)
        }
    }
    
    private func updateStatus(from neStatus: NEVPNStatus) {
        switch neStatus {
        case .connected:
            self.status = .connected
            self.isConnected = true
            self.log("VPN đã kết nối thành công! Toàn bộ mạng đang đi qua 103.238.234.204.")
        case .connecting:
            self.status = .connecting
            self.isConnected = false
            self.log("Trạng thái: Đang thiết lập đường truyền...")
        case .disconnecting:
            self.status = .disconnecting
            self.isConnected = false
            self.log("Trạng thái: Đang ngắt kết nối...")
        case .disconnected, .invalid:
            self.status = .disconnected
            self.isConnected = false
            self.log("Trạng thái: Đã ngắt kết nối.")
        case .reasserting:
            self.status = .connecting
            self.isConnected = false
            self.log("Trạng thái: Đang kết nối lại...")
        @unknown default:
            self.status = .disconnected
            self.isConnected = false
        }
    }
    
    func measureLatency() {
        guard let url = URL(string: "http://\(serverIP):\(serverPort)/ca.crt") else { return }
        let start = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: url, timeoutInterval: 3.0)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if error == nil, let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                let diff = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                DispatchQueue.main.async {
                    self?.latencyMs = diff
                }
            } else {
                DispatchQueue.main.async {
                    self?.latencyMs = nil
                }
            }
        }.resume()
    }
    
    func openCertificateDownload() {
        let certUrl = "http://\(serverIP):\(serverPort)/ca.crt"
        if let url = URL(string: certUrl) {
            log("Mở Safari tải CA Certificate...")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func openSettingsTrust() {
        log("Mở Cài đặt hệ thống iOS...")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
