//
//  DeviceService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI
import UIKit

protocol DeviceService {
    var deviceType: DeviceType { get }
    var screenSize: CGSize { get }
    var isLowPerformanceDevice: Bool { get }
    func adaptBubbleCount(for settings: GameSettings) -> Int
    func getOptimalBubbleSize() -> CGFloat
}

enum DeviceType {
    case iPhone
    case iPhonePlus
    case iPadMini
    case iPad
    case iPadPro
    
    var maxBubbleCount: Int {
        switch self {
        case .iPhone: return 15
        case .iPhonePlus: return 20
        case .iPadMini: return 25
        case .iPad: return 30
        case .iPadPro: return 40
        }
    }
    
    var defaultBubbleSize: CGFloat {
        switch self {
        case .iPhone: return 40.0
        case .iPhonePlus: return 45.0
        case .iPadMini: return 50.0
        case .iPad: return 55.0
        case .iPadPro: return 60.0
        }
    }
}

class DeviceServiceImpl: DeviceService {
    private let _deviceType: DeviceType
    private let _screenSize: CGSize
    private let _isLowPerformanceDevice: Bool
    
    init() {
        let screenBounds = UIScreen.main.bounds
        self._screenSize = screenBounds.size
        
        // デバイスタイプの判定
        let screenWidth = min(screenBounds.width, screenBounds.height)
        let screenHeight = max(screenBounds.width, screenBounds.height)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if screenWidth >= 1024 {
                self._deviceType = .iPadPro
            } else if screenWidth >= 768 {
                self._deviceType = .iPad
            } else {
                self._deviceType = .iPadMini
            }
        } else {
            if screenHeight >= 736 {
                self._deviceType = .iPhonePlus
            } else {
                self._deviceType = .iPhone
            }
        }
        
        // 低性能デバイスの判定（A10以前のチップ）
        self._isLowPerformanceDevice = {
            let modelName = UIDevice.current.model
            let systemVersion = UIDevice.current.systemVersion
            
            // iOS 15未満または古いデバイスモデルは低性能と判定
            if let majorVersion = Int(systemVersion.components(separatedBy: ".").first ?? ""),
               majorVersion < 15 {
                return true
            }
            
            // メモリ容量による判定（2GB未満は低性能）
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            return physicalMemory < 2_000_000_000 // 2GB
        }()
    }
    
    var deviceType: DeviceType {
        return _deviceType
    }
    
    var screenSize: CGSize {
        return _screenSize
    }
    
    var isLowPerformanceDevice: Bool {
        return _isLowPerformanceDevice
    }
    
    func adaptBubbleCount(for settings: GameSettings) -> Int {
        let baseBubbleCount = settings.bubbleCount
        let maxCount = deviceType.maxBubbleCount
        
        // 低性能デバイスの場合はさらに削減
        let performanceMultiplier: Double = isLowPerformanceDevice ? 0.7 : 1.0
        
        let adaptedCount = Int(Double(min(baseBubbleCount, maxCount)) * performanceMultiplier)
        return max(5, adaptedCount) // 最低5個は保証
    }
    
    func getOptimalBubbleSize() -> CGFloat {
        let baseSize = deviceType.defaultBubbleSize
        
        // 画面サイズに応じた調整
        let screenScale = min(screenSize.width, screenSize.height) / 375.0 // iPhone標準幅を基準
        
        return baseSize * max(0.8, min(1.5, screenScale))
    }
}