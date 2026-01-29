//
//  PlayerControlsView.swift
//  Music
//
//  Created by Mayning on 2026/1/20.
//

import SwiftUI

struct PlayerView: View {

	@ObservedObject var mps: MusicService
	@ObservedObject var ps = ProgressService.shared

	let namespace: Namespace.ID
	@Binding var isExpanded: Bool
	@Binding var dragOffset: CGFloat

	// 背景颜色状态默认为黑色，如果有图片则计算图片颜色
	@State private var dynamicBackgroundColor: Color = .black
	// MARK: - 进度条状态
	@State private var draggingProgress: Double?  // 拖动时的进度值
	@State private var isDragging: Bool = false  // 是否正在拖动

	var body: some View {
		ZStack(alignment: .top) {
			// MARK: - 背景层动态颜色
			dynamicBackgroundColor
				.ignoresSafeArea()
				// 叠加一层黑色半透明蒙层，防止背景太亮影响文字阅读
				.overlay(Color.black.opacity(0.4))
				.overlay(
					Rectangle().fill(Material.ultraThinMaterial)
				)

			VStack(spacing: 25) {
				Spacer()
				// 顶部小把手
				Capsule()
					.fill(Color.white.opacity(0.3))
					.frame(width: 80, height: 5)
					.padding(.top, 10)

				let currentItem = mps.currentMusic
				Spacer()

				// MARK: - 大封面图
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
				.frame(width: 300, height: 300)
				.background(Color.gray.opacity(0.1))
				.clipShape(RoundedRectangle(cornerRadius: 20))
				.shadow(color: .black.opacity(0.5), radius: 20)
				.matchedGeometryEffect(id: "cover", in: namespace)

				// 歌曲信息
				VStack(spacing: 5) {
					Text(currentItem?.title ?? " ")
						.font(.title)
						.fontWeight(.bold)
						.foregroundColor(.white)
						.matchedGeometryEffect(id: "title", in: namespace)

					Text(currentItem?.artist ?? " ")
						.font(.title2)
						.foregroundColor(.white.opacity(0.8))
						.matchedGeometryEffect(id: "artist", in: namespace)
				}

				// MARK: - 进度条区域,可以拖动和点击
				VStack(spacing: 10) {
					GeometryReader { geometry in
						Slider(
							value: Binding(
								get: {
									// 拖动时显示临时值，否则显示真实播放进度
									if isDragging,
										let dragging = draggingProgress
									{
										return dragging
									} else {
										return ps.progress
									}
								},
								set: { newValue in
									// 拖动时只更新临时状态，不触发跳转
									draggingProgress = newValue
								}
							),
							in: 0...1
						)
						.accentColor(.white)
						.simultaneousGesture(
							DragGesture(minimumDistance: 0)
								.onChanged { _ in
									if !isDragging {
										isDragging = true
										ps.isUserInteracting = true  // 暂停进度条自动更新
									}
								}
								.onEnded { value in
									// 拖动结束更新
									if let target = draggingProgress {
										mps.seek(to: target * ps.duration)
									}
									// 点击进度条跳转

									let rawPercentage =
										value.location.x / geometry.size.width
									let percentage = max(
										0.0,
										min(1.0, rawPercentage)
									)
									mps.seek(to: percentage * ps.duration)

									// 重置状态
									isDragging = false
									draggingProgress = nil
									ps.isUserInteracting = false
								}
						)
					}
					.frame(height: 30)
					.padding(.horizontal)

					// 时间显示
					HStack {
						Text(
							formattedTime(
								times: isDragging
									? (draggingProgress ?? 0) * ps.duration
									: ps.progress * ps.duration
							)
						)
						.font(.caption)
						.foregroundColor(.white)
						Spacer()
						Text(formattedTime(times: ps.duration))
							.font(.caption)
							.foregroundColor(.white)
					}
					.padding(.horizontal)
				}

				Spacer()

// MARK: - 播放控制按钮
				HStack(spacing: 60) {
					Button(action: { mps.toPrevious() }) {
						Image(systemName: "backward.fill")
							.font(.title)
							.foregroundColor(.white)
					}
					Button(action: {
						guard let currentItem = mps.currentMusic else { return }
						mps.currentState == .playing
							? mps.pause() : mps.play(music: currentItem)
						// 播放/暂停时不需要 seek，保持当前位置即可
					}) {
						ZStack {
							Circle().fill(Color.white).frame(
								width: 70,
								height: 70
							)
							Image(
								systemName: mps.currentState == .playing
									? "pause.fill" : "play.fill"
							)
							.font(.title)
							.foregroundColor(.black)
						}
					}
					Button(action: { mps.toNext() }) {
						Image(systemName: "forward.fill")
							.font(.title)
							.foregroundColor(.white)
					}
				}

				Spacer().frame(height: 50)
			}
			.padding()
		}
		.ignoresSafeArea()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.offset(y: dragOffset)  // 跟随手势移动
		.gesture(
			DragGesture()
				.onChanged { value in
					// 只能向下拖动
					if value.translation.height > 0 {
						self.dragOffset = value.translation.height
					}
				}
				.onEnded { value in
					// 拖动超过距离关闭全屏
					if value.translation.height > 150 {
						withAnimation(.spring()) {
							isExpanded = false
							dragOffset = 0
						}
					} else {
						// 回弹
						withAnimation(.spring()) {
							dragOffset = 0
						}
					}
				}
		)
		.onChange(of: mps.currentMusic) { _, newItem in
			updateBackgroundColor(from: newItem)
		}
		.onAppear {
			updateBackgroundColor(from: mps.currentMusic)
		}
	}
	private func updateBackgroundColor(from item: MusicItem?) {
		guard let path = item?.coverPath,
			let uiImage = UIImage(contentsOfFile: path)
		else {
			// 如果没有封面，恢复默认黑色
			withAnimation(.easeInOut(duration: 0.5)) {
				self.dynamicBackgroundColor = .black
			}
			return
		}

		// 在后台线程计算颜色，避免卡顿 UI
		DispatchQueue.global(qos: .userInitiated).async {
			if let avgColor = uiImage.averageColor {
				let color = Color(avgColor)

				// 回到主线程更新 UI
				DispatchQueue.main.async {
					withAnimation(.easeInOut(duration: 0.8)) {
						self.dynamicBackgroundColor = color
					}
				}
			}
		}
	}
}
#Preview {
	ContentView()
}
// MARK: - UIImage 颜色提取扩展
extension UIImage {
	/// 获取图片的平均颜色
	var averageColor: UIColor? {
		// 1. 将图片绘制到 1x1 的位图上下文中，以获取平均色
		guard let cgImage = self.cgImage else { return nil }

		let size = CGSize(width: 1, height: 1)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

		guard
			let context = CGContext(
				data: nil,
				width: 1,
				height: 1,
				bitsPerComponent: 8,
				bytesPerRow: 4,
				space: colorSpace,
				bitmapInfo: bitmapInfo
			)
		else {
			return nil
		}

		context.draw(cgImage, in: CGRect(origin: .zero, size: size))

		guard let data = context.data else { return nil }
		let pointer = data.bindMemory(to: UInt8.self, capacity: 4)

		// 2. 读取像素数据并转换为 UIColor
		let red = CGFloat(pointer[0]) / 255.0
		let green = CGFloat(pointer[1]) / 255.0
		let blue = CGFloat(pointer[2]) / 255.0
		let alpha = CGFloat(pointer[3]) / 255.0

		return UIColor(red: red, green: green, blue: blue, alpha: alpha)
	}
}
