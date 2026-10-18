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
    @Published var isProcessing: Bool = false
    @Published var serverIP: String = "103.238.234.204"
    @Published var serverPort: Int = 8080
    @Published var latencyMs: Int? = nil
    @Published var logs: [String] = []
    
    private var manager: NETunnelProviderManager?
    private var timer: Timer?
    
    init() {
        log("Khởi tạo hệ thống ProxyBytes VPN Client...")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        // Only load existing configuration to display current state, DO NOT auto-save on startup!
        checkExistingStatus()
        
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
            if self.logs.count > 60 {
                self.logs.removeLast()
            }
        }
    }
    
    // Dynamically locate the actual appex bundle identifier inside PlugIns/ directory
    func findTunnelBundleId() -> String {
        let pluginsURL = Bundle.main.bundleURL.appendingPathComponent("PlugIns")
        if let contents = try? FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil) {
            for url in contents where url.pathExtension == "appex" {
                if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                    return bundleId
                }
            }
        }
        let baseBundleId = Bundle.main.bundleIdentifier ?? "com.proxybytes.vpn"
        return "\(baseBundleId).tunnel"
    }
    
    func checkExistingStatus() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                self.log("Đọc cấu hình hệ thống: \(error.localizedDescription)")
                return
            }
            
            if let existing = managers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol) != nil }) {
                self.manager = existing
                DispatchQueue.main.async {
                    self.updateStatus(from: existing.connection.status)
                    self.log("Đã phát hiện cấu hình VPN trong hệ thống.")
                }
            } else {
                DispatchQueue.main.async {
                    self.log("Hệ thống sẵn sàng. Nhấn 'BẮT ĐẦU KẾT NỐI' để chạy.")
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
        guard !isProcessing else {
            log("Yêu cầu đang được xử lý, vui lòng chờ...")
            return
        }
        
        isProcessing = true
        status = .connecting
        log("Đang cấu hình và kích hoạt VPN tới \(serverIP):\(serverPort)...")
        
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.status = .error(error.localizedDescription)
                    self.log("Lỗi load cấu hình: \(error.localizedDescription)")
                }
                return
            }
            
            // Find existing or instantiate new manager
            let targetManager = managers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol) != nil }) ?? NETunnelProviderManager()
            
            let realTunnelId = self.findTunnelBundleId()
            self.log("Bundle Target: \(realTunnelId)")
            
            let proto = (targetManager.protocolConfiguration as? NETunnelProviderProtocol) ?? NETunnelProviderProtocol()
            proto.providerBundleIdentifier = realTunnelId
            proto.serverAddress = "\(self.serverIP):\(self.serverPort)"
            
            targetManager.protocolConfiguration = proto
            targetManager.localizedDescription = "ProxyBytes 103.238.234.204"
            targetManager.isEnabled = true
            
            targetManager.saveToPreferences { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        let nsErr = error as NSError
                        self.status = .error("Lưu thất bại (\(nsErr.code))")
                        self.log("Lỗi lưu cấu hình: [\(nsErr.domain) \(nsErr.code)] \(error.localizedDescription)")
                        self.log("Gợi ý: Cần chấp nhận quyền VPN từ hộp thoại thông báo của iOS.")
                    }
                    return
                }
                
                // IMPORTANT: Must reload from system preferences so nehelper attaches the active daemon handle
                NETunnelProviderManager.loadAllFromPreferences { [weak self] reloadedManagers, error in
                    guard let self = self else { return }
                    self.isProcessing = false
                    
                    guard let activeManager = reloadedManagers?.first(where: { ($0.protocolConfiguration as? NETunnelProviderProtocol) != nil }) else {
                        DispatchQueue.main.async {
                            self.status = .error("Không tìm thấy profile sau lưu")
                            self.log("Lỗi: Không tìm thấy profile VPN vừa lưu.")
                        }
                        return
                    }
                    
                    self.manager = activeManager
                    
                    // Small delay to let iOS preferences synchronize
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        do {
                            try activeManager.connection.startVPNTunnel()
                            self.log("Đã gửi yêu cầu startVPNTunnel thành công!")
                        } catch {
                            DispatchQueue.main.async {
                                let nsErr = error as NSError
                                self.status = .error("Start thất bại (\(nsErr.code))")
                                self.log("Lỗi startVPNTunnel: [\(nsErr.domain) \(nsErr.code)] \(error.localizedDescription)")
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
            self.log("VPN đã kết nối thành công! Toàn bộ traffic đang đi qua Proxy.")
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
    
    func openMobileConfigDownload() {
        let profileUrl = "https://github.com/sonank077/login_app/releases/download/v1.0.4/ProxyBytes.mobileconfig"
        if let url = URL(string: profileUrl) {
            log("Mở Safari cài đặt cấu hình VPN Profile (.mobileconfig)...")
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
