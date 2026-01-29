//
//  MusicListView.swift
//  Music
//
//  Created by Mayning on 2026/1/20.
//

import SwiftUI

struct MusicListView: View {

	@ObservedObject var mps: MusicService
	// 用于点击行时的高亮动画
	@State private var tappedId: UUID? = nil
	// 搜索字符串
	@State private var searchText = ""
	// 搜索结果
	@State private var searchResults: [MusicItem] = []
	// 搜索状态
	@State private var isSearching = false

	var body: some View {

		VStack(spacing: 0) {
			// MARK: - 顶部工具栏
			HStack(spacing: 10) {
				Spacer()
				if !isSearching {
					// 正常状态---
					Button {
						playRandom()
					} label: {
						Image(systemName: "shuffle.circle")
							.font(.system(size: 30, weight: .medium))
							.foregroundStyle(Color.secondary)
							.symbolEffect(
								.bounce.down.wholeSymbol,
								options: .nonRepeating
							)
							.frame(width: 55, height: 45)
							.background(
								.ultraThinMaterial,
								in: RoundedRectangle(cornerRadius: 25)
							)
					}
					.glassEffect(
						.regular
							.interactive()
					)

					Button {
						// 搜索按钮
						withAnimation {
							isSearching = true
						}
					} label: {
						HStack(spacing: 6) {
							Image(systemName: "magnifyingglass")
								.font(.system(size: 25, weight: .medium))
								.foregroundColor(.secondary)

							Text("搜索")
								.font(.subheadline)
								.foregroundColor(.secondary)
								.opacity(0.5)

						}
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.background(
							.ultraThinMaterial,
							in: RoundedRectangle(cornerRadius: 25)
						)

					}
					.glassEffect(
						.regular
							.interactive()
					)

				} else {
					// 搜索状态---
					// 搜索输入框
					HStack(spacing: 5) {
						Image(systemName: "magnifyingglass")
							.foregroundColor(.secondary)

						TextField("搜索歌曲、歌手、专辑...", text: $searchText)
							.submitLabel(.search)

						// 清除按钮
						if !searchText.isEmpty {
							Button {
								searchText = ""
							} label: {
								Image(systemName: "xmark.circle.fill")
									.foregroundColor(.secondary)
							}
						}
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(
						Color(UIColor.systemBackground)
					)
					.cornerRadius(20)
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)

					// 取消按钮
					Button("取消") {
						withAnimation {
							isSearching = false
							// 退出时清空搜索词
							searchText = ""
						}
					}
					.foregroundColor(.blue)
				}

			}
		}
		.padding(.horizontal)
		.padding(.vertical, 10)
		// MARK: - 歌曲列表
		List {
			ForEach(filteredQueue) { item in
				Button(action: {
					// 播放音乐
					mps.play(music: item)

					// 点击高亮
					withAnimation(.easeOut(duration: 0.1)) {
						tappedId = item.id
					}
					// 0.2 秒后自动取消高亮
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						withAnimation {
							tappedId = nil
						}
					}
				}) {
					ListView(item: item, mps: mps)
				}
				.buttonStyle(PlainButtonStyle())
				.listRowBackground(
					tappedId == item.id ? Color.gray.opacity(0.3) : Color.clear
				)
				.listRowInsets(
					EdgeInsets(top: 10, leading: 0, bottom: 8, trailing: 0)
				)
			}
		}
		.listStyle(PlainListStyle())
		.overlay(
			Group {
				if isSearching && filteredQueue.isEmpty {
					Text("没有找到相关歌曲")
						.foregroundColor(.secondary)
				}
			}
		)
		// 下拉后随机开始播放
		.refreshable {
			mps.shuffleQueue()
		}
	}
	// MARK: - 随机播放和过滤列表
	private func playRandom() {
		guard !mps.queue.isEmpty else { return }
		let randomIndex = Int.random(in: 0..<mps.queue.count)
		let randomMusic = mps.queue[randomIndex]
		mps.play(music: randomMusic)
	}
	private var filteredQueue: [MusicItem] {
		if !isSearching || searchText.isEmpty {
			return mps.queue
		}
		return mps.queue.filter { item in
			item.title.localizedCaseInsensitiveContains(searchText)
				|| item.artist.localizedCaseInsensitiveContains(searchText)
				|| item.album.localizedCaseInsensitiveContains(searchText)
		}
	}
}
// MARK: - 歌曲列表行
struct ListView: View {
	let item: MusicItem
	@ObservedObject var mps: MusicService

	var body: some View {

		HStack(spacing: 12) {
			// 封面图
			Group {
				if let path = item.coverPath,
					let uiImage = UIImage(contentsOfFile: path)
				{

					Image(uiImage: uiImage)
						.resizable()
						.aspectRatio(contentMode: .fill)
				} else {
					Image(systemName: "music.note")
						.foregroundColor(.red)
						.font(.title)
				}
			}
			.frame(width: 55, height: 55)
			.background(Color.gray.opacity(0.1))
			.clipShape(RoundedRectangle(cornerRadius: 10))
			//			.onAppear {
			//				if Image == nil {
			//					//do
			//				}
			//			}

			// 信息：歌曲名，演唱者，时长
			VStack(alignment: .leading, spacing: 5) {
				Text(item.title)
					.font(.headline)
					.foregroundColor(Color.primary)
					.lineLimit(1)

				Text(item.artist)
					.font(.subheadline)
					.foregroundColor(Color.secondary)
					.lineLimit(1)
			}
			Spacer()
			Text(formattedTime(times: item.duration))
				.font(.caption)
				.foregroundColor(Color.secondary)
				.padding(.trailing, 8)
		}
		.padding(.horizontal)
		.cornerRadius(30)
		.padding(.horizontal)
	}
}

#Preview {
	ContentView()
	//MusicListView(mps: MusicService())
}
