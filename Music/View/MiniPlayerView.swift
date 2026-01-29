//
//  MiniPlayerView.swift
//  Music
//
//  Created by Mayning on 2026/1/21.
//

import SwiftUI

struct MiniPlayerView: View {

	@ObservedObject var mps: MusicService
	@ObservedObject var ps = ProgressService.shared
	@Binding var isExpanded: Bool
	let namespace: Namespace.ID
// MARK: - 手势状态
	@State private var dragOffset: CGFloat = 0  // 上下拖动来展开或缩小
	@State private var textOffset: CGFloat = 0  // 左右拖动切换上下一首

	var body: some View {
		let currentItem = mps.currentMusic

		HStack(spacing: 12) {
// MARK: - 封面
			Group {
				if let path = currentItem?.coverPath,
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
			.matchedGeometryEffect(id: "cover", in: namespace)  //动画
			.zIndex(2)  // 在文字上，这样划动文字时，会在图片下方穿过。
// MARK: - 歌曲信息
			VStack(alignment: .leading, spacing: 2) {
				Text(currentItem?.title ?? "No Music")
					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(.primary)
					.matchedGeometryEffect(id: "title", in: namespace)

				Text(currentItem?.artist ?? "--")
					.font(.system(size: 12))
					.foregroundColor(.secondary)
					.matchedGeometryEffect(id: "artist", in: namespace)
			}
			
			.lineLimit(1)
			// 点击文字区域就可以拖动
			.contentShape(Rectangle())
			.offset(x: textOffset)  // 仅文字移动
			.zIndex(1)
			.clipped()
			.gesture(
				DragGesture(minimumDistance: 20)
					.onChanged { value in
						// 拖动时，文字跟随手指轻微移动
						self.textOffset = value.translation.width * 0.5
					}
					.onEnded { value in
						// 拖动后恢复位置
						withAnimation(.spring()) {
							self.textOffset = 0
						}
						if value.translation.width < -40 {
							// 向左滑 --> 下一首
							mps.toNext()
						} else if value.translation.width > 40 {
							// 向右滑 --> 上一首
							mps.toPrevious()
						}
					}
			)
			VStack {
				Text(
					formattedTime(
						times: ps.progress * ps.duration
					)
				)
			}

			Spacer()

// MARK: - 控制按钮
			Button(action: {
				guard let currentItem = mps.currentMusic else { return }
				mps.currentState == .playing
					? mps.pause() : mps.play(music: currentItem)
			}) {
				Image(
					systemName: mps.currentState == .playing
						? "pause.fill" : "play.fill"
				)
				.foregroundColor(.primary)
			}
			// 下一首
			Button(action: { mps.toNext() }) {
				Image(systemName: "forward.fill")
					.foregroundColor(.primary)
			}
		}
		.padding(12)
		.background(.ultraThinMaterial)
		.cornerRadius(25)
		.padding(.horizontal, 16)
		.padding(.bottom, 20)
		.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
// MARK: - 展开手势 (上滑/点击)
		.gesture(
			DragGesture()
				.onChanged { value in
					// 只能向上拖动
					if value.translation.height < 0 {
						self.dragOffset = value.translation.height
					}
				}
				.onEnded { value in
					// 如果向上拖动距离超过一定距离就展开
					if value.translation.height < -50 {
						withAnimation {
							isExpanded = true
						}
					}
					self.dragOffset = 0
				}
		)
		.offset(y: dragOffset * 0.5)  //阻尼效果
		.onTapGesture {
			// 点击也可以展开
			withAnimation {
				isExpanded = true
			}
		}

	}
}
#Preview {
	ContentView()
}
