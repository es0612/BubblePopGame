//
//  AudioEngineStartupTests.swift
//  BubblePopGameTests
//
//  #92: AudioServiceImpl を作っただけで AVAudioEngine を起動しない
//

import Testing
@testable import BubblePopGame

@MainActor
@Suite("AudioServiceImpl の生成時に AVAudioEngine を起動しない (#92)")
struct AudioEngineStartupTests {

    @Test("作ったばかりの AudioServiceImpl では AVAudioEngine が動いていない")
    func engineIsNotStartedOnInit() {
        let service = AudioServiceImpl()

        #expect(service.isEngineRunning == false)
    }
}
