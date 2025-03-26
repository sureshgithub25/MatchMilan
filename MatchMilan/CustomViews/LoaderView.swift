//
//  LoaderView.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import SwiftUI

struct PulseLoaderView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.blue, lineWidth: 4)
                .frame(width: 50, height: 50)
                .scaleEffect(scale)
                .opacity(opacity)
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
        }
        .onAppear {
            scale = 1.2
            opacity = 0.3
        }
    }
}

#Preview {
    PulseLoaderView()
}

