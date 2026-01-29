//
//  LocalMusicSource.swift
//  Music
//
//  Created by Mayning on 2026/1/20.
//

import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI

// 内部源，测试用
class LocalMusicSource: NSObject, AVAudioPlayerDelegate {

	static let shared = LocalMusicSource()

	override init() {
		// 继承NSObject，需要显式调用父类初始化
		super.init()
	}

	private var player: AVAudioPlayer?
	// 记录当前播放时间
	private var currentTime: TimeInterval = 0
	// 记录当前播放时间
	private var totalDuration: TimeInterval = 0

	// 当一首歌播完或播放出错时触发，用于通知控制器播放下一首
	var onPlaybackFinished: (() -> Void)?

	// MARK: 初始化，配置音频播放类别并激活
	func initialize() throws {

		do {
			try AVAudioSession.sharedInstance().setCategory(
				.playback,
				mode: .default
			)
			try AVAudioSession.sharedInstance().setActive(true)
		} catch {
			throw PlayerError.playFailed("initialize error")
		}
	}
	// MARK: 播放控制
	/// 播放指定的音乐
	/// - Parameter music: 包含文件路径和扩展名的音乐项模型
	func play(music: MusicItem) throws {
//		 let fileManager = FileManager.default
//		 guard
//			 let documentsURL = fileManager.urls(
//				 for: .documentDirectory,
//				 in: .userDomainMask
//			 ).first
//		 else {
//			 throw PlayerError.playFailed("无法访问文档目录")
//		 }
//
//		 // 检查文件是否存在
//		 guard fileManager.fileExists(atPath: music.filePath.path) else {
//			 throw PlayerError.playFailed(
//				 "文件不存在: \(music.filePath)"
//			 )
//		 }
		do {
			// 如果当前正在播放，停止
			player?.stop()

			player = try AVAudioPlayer(contentsOf: music.filePath)
			//player = try AVAudioPlayer(contentsOf: music.filePath)  //这是文档目录的。

			// 便监听播放结束和错误事件
			player?.delegate = self
			player?.volume = 0.5
			player?.prepareToPlay()
			player?.play()
			// 当前歌曲的总时长和
			totalDuration = player?.duration ?? 0
			currentTime = 0

		} catch {
			throw PlayerError.playFailed("player error...")
		}

	}

	/// 暂停播放
	func pause() {
		player?.pause()
		// 更新记录的时间点，以便恢复时状态准确
		currentTime = player?.currentTime ?? 0

	}

	/// 跳转播放进度
	/// - Parameter time: 跳转目标时间点（秒）
	func seek(to time: TimeInterval) {
		player?.currentTime = time
		currentTime = time
	}

	/// 获取当前播放时间
	/// - Returns: <#description#>
	func getCurrentTime() -> TimeInterval {
		return player?.currentTime ?? currentTime
	}

	/// 获取音频总时长
	/// - Returns: <#description#>
	func getDuration() -> TimeInterval {
		return player?.duration ?? totalDuration
	}
	/// 判断当前是否正在播放
	/// - Returns: <#description#>
	func isPlaying() -> Bool {
		return player?.isPlaying ?? false
	}

}

// MARK: - AVAudioPlayerDelegate (播放器代理回调)
extension LocalMusicSource {
	func audioPlayerDidFinishPlaying(
		_ player: AVAudioPlayer,
		successfully flag: Bool
	) {
		if flag {
			// 播放成功结束，触发回调
			onPlaybackFinished?()
		}
	}
	// 解码发生错误的代理回调
	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			//同调用回调
			self.onPlaybackFinished?()
		}
	}
}
