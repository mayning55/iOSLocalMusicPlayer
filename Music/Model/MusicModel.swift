//
//  MusicModel.swift
//  Music
//
//  Created by Mayning on 2026/1/19.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

// 歌曲信息类型属性
struct MusicItem: Identifiable, Equatable {
	let id = UUID()
	let title: String
	let artist: String
	let album: String
	let duration: TimeInterval
	let filePath: URL
	let fileExt: String
	var coverPath: String?
	//let lrc: String //歌词。。。。todo.....
}
// 播放状态,Equatable-可用于值比较
enum PlayerState: Equatable {
	case playing
	case paused
	case idle
}

enum PlayerError: Error {
	case playFailed(String)
}

func formattedTime(times: TimeInterval) -> String {

	let minutes = Int(times) / 60
	let seconds = Int(times) % 60
	return String(format: "%d:%02d", minutes, seconds)
}
