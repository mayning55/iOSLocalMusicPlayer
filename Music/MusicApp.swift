//
//  MusicApp.swift
//  Music
//
//  Created by Mayning on 2026/1/19.
//

import SwiftUI

@main
struct MusicApp: App {
	
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


/*
 Model
	MusicModel - 歌曲的属性和状态等
 Service
	DataService - 提供音乐文件的方式，应用内部的用于开发测试，
		loadLocalDocumentsMusics - 加载目录
 
 
 todo...
	1 - 小窗口播放done
	2 - 后台播放done
	3 - 搜索done
长期：
	1 - 专辑图片done
	2 - 歌词
 
 注意事项：
 文件名有空格的问题，路径不能识别
 */
