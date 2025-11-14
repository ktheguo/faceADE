//
//  NeutralRecorder.swift
//  faceADE
//
//  Created by Anthony Newman on 10/22/25.
//
//  For Smile Metrics Popup

import UIKit

// What we sample each tick (use Float to match your codebase)
struct Metrics: Codable {
    var rightMouthArea: Float
    var leftMouthArea: Float
    var rightBotLipMes: Float
    var leftBotLipMes: Float
}

struct Sample: Codable {
    let t: TimeInterval
    let metrics: Metrics
}

final class NeutralRecorder {
    private var timer: Timer?
    private var startTime: Date?
    private var samples: [Sample] = []
    private var duration: TimeInterval = 5
    private var interval: TimeInterval = 0.1
    private var sampleBlock: (() -> Metrics)?
    private var progressHandler: ((Double) -> Void)?
    private var completion: (([Sample]) -> Void)?

    var isRecording: Bool { timer != nil }

    func start(duration: TimeInterval = 5,
               interval: TimeInterval = 0.1,
               sampleBlock: @escaping () -> Metrics,
               progress: ((Double) -> Void)? = nil,
               completion: @escaping ([Sample]) -> Void) {
        guard timer == nil else { return }
        self.duration = duration
        self.interval = interval
        self.sampleBlock = sampleBlock
        self.progressHandler = progress
        self.completion = completion
        self.samples.removeAll()
        self.startTime = Date()

        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(start)

            if let m = self.sampleBlock?() {
                self.samples.append(Sample(t: elapsed, metrics: m))
            }

            let p = min(1.0, elapsed / self.duration)
            self.progressHandler?(p)

            if elapsed >= self.duration {
                self.stop()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stop() {
        guard let timer else { return }
        timer.invalidate()
        self.timer = nil
        let final = samples
        samples.removeAll()
        DispatchQueue.main.async { [completion] in
            completion?(final)
        }
    }
}

