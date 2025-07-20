//
//  PerformanceService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import QuartzCore
import UIKit

protocol PerformanceService {
    var currentFPS: Double { get }
    var averageFPS: Double { get }
    var isPerformanceGood: Bool { get }
    func startMonitoring()
    func stopMonitoring()
    func shouldReduceBubbles() -> Bool
    func getPerformanceAdjustment() -> Double
}

class PerformanceServiceImpl: PerformanceService {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsHistory: [Double] = []
    private let maxHistoryCount = 60 // 1秒間のフレーム履歴
    
    private var _currentFPS: Double = 60.0
    private var _averageFPS: Double = 60.0
    
    var currentFPS: Double {
        return _currentFPS
    }
    
    var averageFPS: Double {
        return _averageFPS
    }
    
    var isPerformanceGood: Bool {
        return averageFPS >= 55.0 // 55FPS以上を良好とする
    }
    
    func startMonitoring() {
        stopMonitoring() // 既存の監視を停止
        
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.add(to: .main, forMode: .common)
        
        lastTimestamp = CACurrentMediaTime()
        frameCount = 0
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func frameUpdate(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        
        if lastTimestamp > 0 {
            let deltaTime = currentTime - lastTimestamp
            
            if deltaTime > 0 {
                let fps = 1.0 / deltaTime
                _currentFPS = fps
                
                // FPS履歴を更新
                fpsHistory.append(fps)
                if fpsHistory.count > maxHistoryCount {
                    fpsHistory.removeFirst()
                }
                
                // 平均FPS計算
                if !fpsHistory.isEmpty {
                    _averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
                }
            }
        }
        
        lastTimestamp = currentTime
        frameCount += 1
    }
    
    func shouldReduceBubbles() -> Bool {
        // 平均FPSが50以下の場合、バブル数を減らすべき
        return averageFPS < 50.0
    }
    
    func getPerformanceAdjustment() -> Double {
        // FPSに基づく調整係数を返す（0.5〜1.0）
        if averageFPS >= 55.0 {
            return 1.0 // フル性能
        } else if averageFPS >= 45.0 {
            return 0.8 // 軽微な調整
        } else if averageFPS >= 35.0 {
            return 0.6 // 中程度の調整
        } else {
            return 0.5 // 大幅な調整
        }
    }
    
    deinit {
        stopMonitoring()
    }
}