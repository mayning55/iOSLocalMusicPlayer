//
//  ProgressService.swift
//  Music
//
//  Created by Mayning on 2026/1/20.
//

import Combine
import Foundation

/// 进度计时器，播放界面的进度跟踪
@MainActor
class ProgressService: ObservableObject {

	static let shared = ProgressService()

	@Published var isUserInteracting: Bool = false
	@Published var currentTime: TimeInterval = 0
	@Published var duration: TimeInterval = 0
	@Published var progress: Double = 0

	private var progressCancellable: AnyCancellable?

	private let localSource = LocalMusicSource.shared
	//private let musicSource = MusicSource.shared

	init() {
		setupProgressTimer()
	}
	// 进度计时器逻辑配置
	// 使用 Timer.publish 每 0.1 秒触发一次更新
	private func setupProgressTimer() {
		progressCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
			.autoconnect()
			.sink { [weak self] _ in
				self?.updateProgress()
			}
	}
	private func updateProgress() {
		// 只有在播放时才频繁更新
		guard localSource.isPlaying() else { return }

		// 拖动进度条时，不要更新
		guard !isUserInteracting else { return }

		currentTime = localSource.getCurrentTime()
		duration = localSource.getDuration()

		if duration > 0 {
			progress = currentTime / duration
		}
	}
	func syncTime(time: TimeInterval) {
		self.currentTime = time
		// 重新获取一下时长，防止切歌后时长还没变过来
		self.duration = localSource.getDuration()
		// 根据新时间重新计算进度比例
		if self.duration > 0 {
			self.progress = time / self.duration
		}
	}
}
