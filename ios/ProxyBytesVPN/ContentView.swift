import SwiftUI

struct ContentView: View {
    @StateObject private var vpn = VPNManager.shared
    @State private var isPulsing = false
    @State private var showCertGuide = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.05, blue: 0.09), Color(red: 0.07, green: 0.10, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(vpn.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: vpn.isConnected ? .green : .red, radius: 4)
                                
                                Text("PROXYBYTES VPN")
                                    .font(.system(size: 20, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .tracking(1.2)
                            }
                            
                            Text("Dedicated Core Client • 103.238.234.204")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Latency Pill
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(vpn.latencyMs != nil ? .yellow : .gray)
                            
                            if let ms = vpn.latencyMs {
                                Text("\(ms)ms")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            } else {
                                Text("--")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // MARK: - Central Power Button
                    VStack(spacing: 16) {
                        ZStack {
                            // Pulsing animation when connected
                            if vpn.isConnected {
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 3)
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                                    .opacity(isPulsing ? 0.0 : 1.0)
                                    .animation(
                                        Animation.easeOut(duration: 1.8).repeatForever(autoreverses: false),
                                        value: isPulsing
                                    )
                                    .onAppear { isPulsing = true }
                            }
                            
                            // Outer Glow Ring
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            vpn.isConnected ? Color.green.opacity(0.25) : Color.red.opacity(0.12),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 170, height: 170)
                            
                            // Main Tap Button
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                vpn.toggle()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: vpn.isConnected
                                                    ? [Color(red: 0.05, green: 0.35, blue: 0.20), Color(red: 0.02, green: 0.18, blue: 0.10)]
                                                    : [Color(red: 0.16, green: 0.20, blue: 0.28), Color(red: 0.08, green: 0.11, blue: 0.17)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 130, height: 130)
                                        .shadow(
                                            color: vpn.isConnected ? Color.green.opacity(0.6) : Color.black.opacity(0.8),
                                            radius: vpn.isConnected ? 18 : 10
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(vpn.isConnected ? Color.green : Color.white.opacity(0.15), lineWidth: 2.5)
                                        )
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "power")
                                            .font(.system(size: 42, weight: .bold))
                                            .foregroundColor(vpn.isConnected ? .green : .white)
                                        
                                        Text(vpn.isConnected ? "DISCONNECT" : "CONNECT")
                                            .font(.system(size: 11, weight: .black, design: .monospaced))
                                            .foregroundColor(vpn.isConnected ? .green : .white.opacity(0.8))
                                            .tracking(1.0)
                                    }
                                }
                            }
                        }
                        .frame(height: 190)
                        
                        // Status Badge
                        Text(vpn.status.displayText)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(vpn.isConnected ? .green : (vpn.status.displayText.contains("ĐANG") ? .yellow : .gray))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                    }
                    
                    // MARK: - Server Info Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.cyan)
                            Text("MÁY CHỦ PROXY TÍCH HỢP")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Text("ONLINE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("SERVER IP")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(vpn.serverIP)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("PORT")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("\(vpn.serverPort)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("GIAO THỨC")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("HTTP/HTTPS Global Tunnel")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Certificate Installer Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.yellow)
                            Text("CHỨNG CHỈ CA (SSL ROOT)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Text("Cần cài đặt và bật tin cậy chứng chỉ để mã hóa HTTPS và chạy mượt mà.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                vpn.openCertificateDownload()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 12))
                                    Text("1. Tải Chứng Chỉ")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                vpn.openSettingsTrust()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 12))
                                    Text("2. Mở Cài Đặt")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        Button(action: {
                            vpn.openMobileConfigDownload()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.shield.fill")
                                    .font(.system(size: 13))
                                Text("Cài Đặt Cấu Hình Tự Động (Khuyên Dùng)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.cyan)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                        }
                        DisclosureGroup("Xem hướng dẫn bật Tin Cậy Chứng Chỉ", isExpanded: $showCertGuide) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Bước 1: Bấm 'Tải Chứng Chỉ' qua Safari, chọn 'Cho phép'.")
                                Text("• Bước 2: Vào Cài đặt iPhone -> 'Đã tải về hồ sơ' -> Chọn Cài đặt.")
                                Text("• Bước 3: Vào Cài đặt chung -> Giới thiệu -> Kéo xuống dưới cùng chọn 'Cài đặt tin cậy chứng nhận'.")
                                Text("• Bước 4: Gạt BẬT công tắc xanh cho 'ProxyBytes Root CA'.")
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        }
                        .accentColor(.yellow)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .padding(18)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Activity Logs
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("NHẬT KÝ HOẠT ĐỘNG")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(vpn.logs.prefix(6), id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.85))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(14)
                    .background(Color(red: 0.06, green: 0.08, blue: 0.14))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
