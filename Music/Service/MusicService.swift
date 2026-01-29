//
//  MusicService.swift
//  Music
//
//  Created by Mayning on 2026/1/19.
//

import AVFoundation
import Combine
import Foundation

@MainActor
class MusicService: ObservableObject {

	// MARK: - UI 响应式状态
	@Published var currentState: PlayerState = .idle
	@Published var currentMusic: MusicItem?
	@Published var currentTime: TimeInterval = 0
	@Published var queue: [MusicItem] = []

	// MARK: - 私有属性
	private var currentIndex: Int = 0
	/// 依赖服务
	// 播放源
	private let localSource = LocalMusicSource.shared
	// 数据服务
	private let dataService = PlayerService()

	// MARK: - 初始化
	init() {
		do {
			try localSource.initialize()
			// 加载初始播放列表
			Task {
				self.queue = await dataService.getlocalMusic()
			}

			//配置播放结束后的回调，当本地播放器播放完成一首歌后自动执行 toNext() 切下一首
			localSource.onPlaybackFinished = { [weak self] in
				// 确保在主线程执行 UI 相关操作
				Task { @MainActor in
					self?.toNext()
				}
			}

		} catch {
			//print("初始化失败: \(error)")//--todo: 捕捉错误。
		}

	}

	// MARK: - 播放控制
	func play(music: MusicItem) {
		currentMusic = music
		if let index = queue.firstIndex(where: { $0.id == music.id }) {
			currentIndex = index
		}

		do {
			try localSource.play(music: music)
			currentState = .playing

		} catch {
			//print("播放出错: \(error)")
			currentState = .paused  // --todo：或者一个 error 状态？？
		}
	}

	/// 暂停播放
	func pause() {
		localSource.pause()
		currentState = .paused
	}
	/// 跳转播放进度
	/// - Parameter time: <#time description#>
	func seek(to time: TimeInterval) {
		localSource.seek(to: time)
		ProgressService.shared.syncTime(time: time)
	}

	// MARK: - 列表队列管理
	// 下一首
	func toNext() {
		guard !queue.isEmpty else { return }
		currentIndex = (currentIndex + 1) % queue.count
		let nextMusic = queue[currentIndex]
		play(music: nextMusic)

	}
	// 上一首
	func toPrevious() {
		guard !queue.isEmpty else { return }
		// 如果播放超过5秒，点击上一首重新开始当前歌,否则切到上一首
		let current = localSource.getCurrentTime()
		if current > 5.0 {
			seek(to: 0)
			return
		}
		currentIndex = currentIndex > 0 ? currentIndex - 1 : queue.count - 1
		let prevMusic = queue[currentIndex]
		play(music: prevMusic)
	}

	/// 随机播放
	func shuffleQueue() {
		queue.shuffle()
		if let currentMusic = currentMusic,
			let newIndex = queue.firstIndex(where: { $0.id == currentMusic.id })
		{
			currentIndex = newIndex
		}
		play(music: queue[0])
	}
	/// 在当前队列中搜索歌曲
	/// - Parameter query: 搜索关键词
	/// - Returns: 匹配的歌曲数组
	func searchSongs(query: String) -> [MusicItem] {
		let lowercaseQuery = query.lowercased()

		return queue.filter { item in
			item.title.lowercased().contains(lowercaseQuery)
				|| item.artist.lowercased().contains(lowercaseQuery)
				|| item.album.lowercased().contains(lowercaseQuery)
		}
	}
}
