//
//  Network.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 29/07/25.
//
import SystemConfiguration
import Combine
import Foundation

class Reachability {
    private var reachability: SCNetworkReachability?
    var whenReachable: ((Reachability) -> Void)?
    var whenUnreachable: ((Reachability) -> Void)?
    
    var connection: SCNetworkReachabilityFlags.Connection {
        var flags = SCNetworkReachabilityFlags()
        guard let reachability = reachability, SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return .unavailable
        }
        return flags.connection
    }
    
    init() {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        reachability = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress)
    }
    
    // Add description property
    var description: String {
        switch connection {
        case .wifi: return "Reachable via WiFi"
        case .cellular: return "Reachable via Cellular"
        case .unavailable: return "Not reachable"
        }
    }
    
    func startNotifier() throws {
        guard let reachability = reachability else {
            throw NetworkError.invalidReachability
        }
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedReachability = Unmanaged<Reachability>.fromOpaque(info)
                _ = unmanagedReachability.retain()
                return UnsafeRawPointer(unmanagedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) in
                let unmanagedReachability = Unmanaged<Reachability>.fromOpaque(info)
                unmanagedReachability.release()
            },
            copyDescription: { (info: UnsafeRawPointer) -> Unmanaged<CFString> in
                let unmanagedReachability = Unmanaged<Reachability>.fromOpaque(info)
                let reachability = unmanagedReachability.takeUnretainedValue()
                let description = reachability.description as CFString
                return Unmanaged.passRetained(description)
            }
        )
        
        if !SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            guard let info = info else { return }
            
            let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            reachability.notify(flags)
        }, &context) {
            throw NetworkError.unableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachability, DispatchQueue.main) {
            throw NetworkError.unableToSetDispatchQueue
        }
    }
    
    func stopNotifier() {
        guard let reachability = reachability else { return }
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
    
    private func notify(_ flags: SCNetworkReachabilityFlags) {
        DispatchQueue.main.async {
            if flags.connection != .unavailable {
                self.whenReachable?(self)
            } else {
                self.whenUnreachable?(self)
            }
        }
    }
    
    deinit {
        stopNotifier()
    }
}

extension SCNetworkReachabilityFlags {
    enum Connection {
        case unavailable
        case wifi
        case cellular
    }
    
    var connection: Connection {
        guard isReachable else { return .unavailable }
        
        #if os(iOS)
        if contains(.isWWAN) {
            return .cellular
        }
        #endif
        
        return .wifi
    }
    
    var isReachable: Bool {
        contains(.reachable)
    }
}

enum NetworkError: Error {
    case invalidReachability
    case unableToSetCallback
    case unableToSetDispatchQueue
}

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var networkStatusPublisher: AnyPublisher<Bool, Never> { get }
}

final class NetworkMonitor: NetworkMonitorProtocol {
    static let shared = NetworkMonitor()
    
    private let reachability: Reachability
    private let networkStatusSubject = CurrentValueSubject<Bool, Never>(true)
    
    var networkStatusPublisher: AnyPublisher<Bool, Never> {
        return networkStatusSubject.eraseToAnyPublisher()
    }
    
    var isConnected: Bool {
        return reachability.connection != .unavailable
    }
    
    init() {
        self.reachability = Reachability()
        setupReachability()
    }
    
    private func setupReachability() {
        reachability.whenReachable = { [weak self] _ in
            self?.networkStatusSubject.send(true)
        }
        
        reachability.whenUnreachable = { [weak self] _ in
            self?.networkStatusSubject.send(false)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier: \(error)")
        }
    }
    
    deinit {
        reachability.stopNotifier()
    }
}
