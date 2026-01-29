//
//  PlayerService.swift
//  Music
//
//  Created by Mayning on 2026/1/19.
//

import AVFoundation
import Foundation
import SwiftUI

class PlayerService {

	// MARK: - Properties (属性)
	
	/// 封面缓存文件夹的名称
	private let coverCacheFolderName = "CoverCache"
	
	// MARK: - Initialization (初始化)
	
	init() {}
	
	// MARK: - Public API (公开接口)
	
	/// 获取本地音乐列表的主入口
	/// - Returns: 音乐模型数组
	/// - Note: 当前默认返回 Bundle 内的音乐，如需加载 Documents 目录音乐，请切换注释代码
	func getlocalMusic() async -> [MusicItem] {
		// return await loadLocalDocumentsMusics()
		return await loadBundleMusics()
	}
	
	/// 加载 App Documents 目录下的音乐
	/// - Returns: 音乐模型数组
	func loadDocumentsMusics() async -> [MusicItem] {
		let fileManager = FileManager.default
		guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return []
		}
		
		return await scanDirectory(url: documentsURL, relativePath: "")
	}
	
	/// 加载 App Bundle 内的音乐
	/// - Returns: 音乐模型数组
	func loadBundleMusics() async -> [MusicItem] {
		// 1. 获取 Bundle 的资源目录
		guard let resourceURL = Bundle.main.resourceURL else { return [] }
		let testFolderURL = resourceURL.appendingPathComponent("TestMusics")
		
		// 2. 优先检查 TestMusics 文件夹，如果不存在则扫描整个 Bundle
		if FileManager.default.fileExists(atPath: testFolderURL.path) {
			return await scanDirectory(url: testFolderURL, relativePath: "")
		} else {
			//print("⚠️ 未找到 TestMusics 文件夹，尝试扫描整个  Bundle 资源目录")
			return await scanDirectory(url: resourceURL, relativePath: "")
		}
	}
	
	// MARK: - Core Logic (核心扫描逻辑)
	
	/// 递归扫描指定目录及其子目录下的所有歌曲
	/// - Parameters:
	///   - url: 当前要扫描的目录 URL
	///   - relativePath: 当前的相对路径（用于记录文件层级结构，避免存储绝对路径）
	/// - Returns: 在该目录及子目录中找到的音乐数组
	private func scanDirectory(url: URL, relativePath: String) async -> [MusicItem] {
		var musics: [MusicItem] = []
		let fileManager = FileManager.default
		
		do {
			// 获取当前目录下的所有内容（包括文件和子目录，跳过隐藏文件）
			let contents = try fileManager.contentsOfDirectory(
				at: url,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			)
			
			// 分类容器
			var subdirectories: [URL] = []
			var audioFiles: [URL] = []
			
			// 支持的文件格式后缀
			let supportedAudio = ["mp3", "flac", "m4a"]
			
			// 遍历内容进行分类
			for item in contents {
				// 忽略隐藏文件（以 . 开头）
				if item.lastPathComponent.starts(with: ".") { continue }
				
				var isDirectory: ObjCBool = false
				if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
					if isDirectory.boolValue {
						subdirectories.append(item)
					} else {
						let ext = item.pathExtension.lowercased()
						if supportedAudio.contains(ext) {
							audioFiles.append(item)
						}
						// 图片文件在此处暂不需要单独处理列表，因为 resolveCoverPath 会处理
					}
				}
			}
			
			// 处理当前目录下的音频文件
			for audioFile in audioFiles {
				let asset = AVURLAsset(url: audioFile)
				
				do {
					// 异步加载元数据：时长 和 元数据数组
					let (duration, metadataItems) = try await (asset.load(.duration), asset.load(.metadata))
					let seconds = CMTimeGetSeconds(duration)
					
					// 过滤掉时长小于 1 秒的非音频片段或损坏文件
					if seconds > 1 {
						// 解析元数据（标题、歌手、专辑、内嵌封面）
						let (metaTitle, metaArtist, metaAlbum, embeddedImageData) = await parseMetadata(items: metadataItems)
						
						// 解析封面路径（优先内嵌，其次同级图片）
						let finalCoverPath = resolveCoverPath(
							for: audioFile,
							embeddedData: embeddedImageData,
							siblingFiles: contents // 传入当前目录所有文件以便查找同名封面
						)
						
						// 构建音乐模型对象
						// 注意：MusicItem 需要在项目中定义
						let music = MusicItem(
							title: metaTitle ?? audioFile.deletingPathExtension().lastPathComponent,
							artist: metaArtist ?? "Unknown Artist",
							album: metaAlbum ?? "Unknown Album",
							duration: seconds,
							filePath: audioFile, // 存储 URL 引用
							fileExt: audioFile.pathExtension,
							coverPath: finalCoverPath
						)
						musics.append(music)
					}
				} catch {
					// print("Error: \(audioFile.lastPathComponent) - \(error)")
				}
			}
			
			// 递归处理子目录
			for subdir in subdirectories {
				let subRelativePath = relativePath.isEmpty
					? subdir.lastPathComponent
					: "\(relativePath)/\(subdir.lastPathComponent)"
				
				let subMusics = await scanDirectory(url: subdir, relativePath: subRelativePath)
				musics.append(contentsOf: subMusics)
			}
			
		} catch {
			// print("Error scanning directory \(url.path): \(error)")
		}
		
		return musics
	}
	
	// MARK: - Metadata Parsing (元数据解析)
	
	/// 解析 AVAsset 元数据项
	/// - Parameter items: 原始元数据项数组
	/// - Returns: 包含 (标题, 歌手, 专辑, 封面数据) 的元组
	private func parseMetadata(items: [AVMetadataItem]) async -> (String?, String?, String?, Data?) {
		var title: String?
		var artist: String?
		var album: String?
		var imageData: Data?
		
		for item in items {
			guard let commonKey = item.commonKey?.rawValue else { continue }
			
			switch commonKey {
			case AVMetadataKey.commonKeyTitle.rawValue:
				if let value = try? await item.load(.value) as? String {
					title = value
				}
			case AVMetadataKey.commonKeyArtist.rawValue:
				if let value = try? await item.load(.value) as? String {
					artist = value
				}
			case AVMetadataKey.commonKeyAlbumName.rawValue:
				if let value = try? await item.load(.value) as? String {
					album = value
				}
			case AVMetadataKey.commonKeyArtwork.rawValue:
				if let data = try? await item.load(.dataValue) {
					imageData = data
				}
			default:
				break
			}
		}
		
		return (title, artist, album, imageData)
	}
	
	// MARK: - Cover Handling (封面处理)
	
	/// 【核心方法】解析封面路径
	/// - Parameters:
	///   - audioFileURL: 音频文件的绝对路径 URL
	///   - embeddedData: 音频内嵌的封面数据（如果有）
	///   - siblingFiles: 音频所在目录下的所有文件（用于寻找同名封面）
	/// - Returns: 封面图片的绝对路径字符串，如果找不到则返回 nil
	private func resolveCoverPath(
		for audioFileURL: URL,
		embeddedData: Data?,
		siblingFiles: [URL]
	) -> String? {
		
		// 1. 优先级 A: 处理内嵌封面
		// 无论音频在哪里，内嵌封面都提取并缓存到 Caches 目录，以供统一访问
		if let data = embeddedData {
			// 生成唯一文件名（使用文件名+路径哈希），防止不同歌曲的内嵌封面互相覆盖
			let hashFilename = "\(audioFileURL.lastPathComponent)_\(audioFileURL.path.hashValue).jpg"
			let cacheURL = getCoverCacheDirectory().appendingPathComponent(hashFilename)
			
			// 如果缓存已存在直接返回，否则写入文件
			if FileManager.default.fileExists(atPath: cacheURL.path) {
				return cacheURL.path
			}
			
			do {
				try data.write(to: cacheURL)
				return cacheURL.path
			} catch {
				print("写入内嵌封面失败: \(error)")
			}
		}
		
		// 2. 优先级 B: 处理同级目录图片
		// 逻辑：找到与音频文件同名（不同后缀）的图片文件
		let audioName = audioFileURL.deletingPathExtension().lastPathComponent
		
		// 在同级文件中查找
		let matchedImage = siblingFiles.first { file in
			guard file != audioFileURL else { return false } // 排除音频文件自己
			
			let ext = file.pathExtension.lowercased()
			guard ["jpg", "jpeg", "png"].contains(ext) else { return false } // 必须是图片格式
			
			// 文件名必须相同 (不区分大小写，但注意文件名前后的空格)
			return file.deletingPathExtension().lastPathComponent.lowercased() == audioName.lowercased()
		}
		
		// 如果找到了同名图片，直接返回其绝对路径
		// 【关键点】：无论这个 matchedImage 是在 Bundle 里还是在 Documents 里，它的 path 都是绝对路径，均可直接加载
		if let img = matchedImage {
			return img.path
		}
		
		return nil
	}
	
	/// 获取或创建封面缓存目录，存放专辑封面图片
	/// - Returns: 缓存目录的 URL
	private func getCoverCacheDirectory() -> URL {
		let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		let coverDir = cacheDir.appendingPathComponent(coverCacheFolderName, isDirectory: true)
		
		// 如果目录不存在则创建
		if !FileManager.default.fileExists(atPath: coverDir.path) {
			try? FileManager.default.createDirectory(at: coverDir, withIntermediateDirectories: true)
		}
		return coverDir
	}
}
