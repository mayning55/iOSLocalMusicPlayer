//
//  ContentView.swift
//  Music
//
//  Created by Mayning on 2026/1/19.
//

import SwiftUI

struct ContentView: View {

	@StateObject private var mps = MusicService()
	@StateObject private var ps = ProgressService()

	@Environment(\.colorScheme) var colorScheme

	// 用于播放器展开动画
	@Namespace private var animation

	// 播放器展开状态
	@State var isExpanded: Bool = false
	// 拖拽偏移量
	@State private var dragOffset: CGFloat = 0

	var body: some View {
		NavigationStack {
			ZStack {
				// MARK: - 背景层
				if colorScheme == .dark {
					RadialGradient(
							gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.3)]),
							center: .topLeading,
							startRadius: 100,
							endRadius: 1000
						)
						.ignoresSafeArea()
				} else {
					RadialGradient(
						gradient: Gradient(colors: [Color.white, Color.blue]),
						center: .topLeading,
						startRadius: 100,
						endRadius: 1000
					)
					.ignoresSafeArea()
				}

				// MARK: - 主列表层
				VStack {
					MusicListView(mps: mps)
					Spacer()

				}
				// MARK: - 播放器层
				ZStack {
					// 全屏
					if isExpanded {
						PlayerView(
							mps: mps,
							ps: ps,
							namespace: animation,
							isExpanded: $isExpanded,
							dragOffset: $dragOffset
						)
						.zIndex(2)
						.transition(
							.asymmetric(
								insertion: .opacity,  // 或者 .move(edge: .bottom)
								removal: .opacity
							)
						)
					}
					VStack {
						Spacer()
						// 底部迷你小播放器
						MiniPlayerView(
							mps: mps,
							isExpanded: $isExpanded,
							namespace: animation
						)
						// 当全屏展开时，将迷你播放器移出屏幕外
						.offset(y: isExpanded ? 1000 : 0)
						.zIndex(1)
					}
				}
			}
		}

	}
}

#Preview {
	ContentView()
}
