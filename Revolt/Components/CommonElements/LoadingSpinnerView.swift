//
//  LoadingSpinnerView.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//
//  File from https://github.com/KeatoonMask/SwiftUI-Animation/
//  under the Apache 2.0 license
//

import SwiftUI


struct LoadingSpinnerView: View {

    @State var frameSize: CGSize
    @Binding var isActionComplete: Bool
    
    let rotationTime: Double = 0.75
    let animationTime: Double = 1.9 // Sum of all animation times
    let fullRotation: Angle = .degrees(360)
    static let initialDegree: Angle = .degrees(270)

    @State var spinnerStart: CGFloat = 0.0
    @State var spinnerEndS1: CGFloat = 0.03
    @State var spinnerEndS2S3: CGFloat = 0.03

    @State var rotationDegreeS1 = initialDegree
    @State var rotationDegreeS2 = initialDegree
    @State var rotationDegreeS3 = initialDegree

    var body: some View {
        ZStack {
            if isActionComplete {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.green)
            }
            
            // S3
            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS3, color: Color("themeTertiary"), frameSize: frameSize)

            // S2
            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS2, color: Color("themeSecondary"), frameSize: frameSize)

            // S1
            SpinnerCircle(start: spinnerStart, end: spinnerEndS1, rotation: rotationDegreeS1, color: Color("themePrimary"), frameSize: frameSize)
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .onAppear() {
            self.animateSpinner()
            Timer.scheduledTimer(withTimeInterval: animationTime, repeats: true) { (mainTimer) in
                self.animateSpinner()
            }
        }
    }

    // MARK: Animation methods
    func animateSpinner(with duration: Double, completion: @escaping (() -> Void)) {
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            withAnimation(Animation.easeInOut(duration: self.rotationTime)) {
                completion()
            }
        }
    }

    func animateSpinner() {
        animateSpinner(with: rotationTime) { self.spinnerEndS1 = 1.0 }

        if !isActionComplete {
            animateSpinner(with: (rotationTime * 2) - 0.025) {
                self.rotationDegreeS1 += fullRotation
                self.spinnerEndS2S3 = 0.8
            }
            
            animateSpinner(with: (rotationTime * 2)) {
                self.spinnerEndS1 = 0.03
                self.spinnerEndS2S3 = 0.03
            }
            
            animateSpinner(with: (rotationTime * 2) + 0.0525) { self.rotationDegreeS2 += fullRotation }
            
            animateSpinner(with: (rotationTime * 2) + 0.225) { self.rotationDegreeS3 += fullRotation }
        }
    }
}

// MARK: SpinnerCircle

struct SpinnerCircle: View {
    var start: CGFloat
    var end: CGFloat
    var rotation: Angle
    var color: Color
    
    var frameSize: CGSize

    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(style: StrokeStyle(lineWidth: frameSize.width / 10, lineCap: .round))
            .fill(color)
            .rotationEffect(rotation)
    }
}

#Preview {
    var action = false
    var actionComplete: Binding<Bool> = Binding(get: {action}, set: {a in action = a})
    return LoadingSpinnerView(frameSize: CGSize(width: 100, height: 100), isActionComplete: actionComplete)
        .task {
            try! await Task.sleep(for: .seconds(3))
            action = true
        }
}
