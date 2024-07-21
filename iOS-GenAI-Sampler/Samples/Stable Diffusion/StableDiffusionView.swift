//
//  StableDiffusionView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/21.
//

import SwiftUI
import StableDiffusion

let runningOnMac = ProcessInfo.processInfo.isMacCatalystApp
let deviceHas6GBOrMore = ProcessInfo.processInfo.physicalMemory > 5910000000   // Reported by iOS 17 beta (21A5319a) on iPhone 13 Pro: 5917753344
let deviceHas8GBOrMore = ProcessInfo.processInfo.physicalMemory > 7900000000   // Reported by iOS 17.0.2 on iPhone 15 Pro Max: 8021032960

let deviceSupportsQuantization = {
    if #available(iOS 17, *) {
        true
    } else {
        false
    }
}()

struct StableDiffusionView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    StableDiffusionView()
}

class StableDiffusionState {

//    func hoge(resourceURL: URL, prompt: String, seed: Int) {
//        let pipeline = try! StableDiffusionPipeline(resourcesAt: resourceURL, controlNet: [])
//        try! pipeline.loadResources()
//        let image = try pipeline.generateImages(prompt: prompt, seed: seed).first
//    }
}
