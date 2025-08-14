/// Copyright (c) 2025 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct ConfigurationView: View {
  @Binding var instruction: String?
  @Binding var customTemperature: Bool
  @Binding var temperature: Double?
  @Binding var useGreedy: Bool
  @State var localInstructions = ""
  @State var localTemperature: Double = 0.2

  var formattedTemperatre: String {
    String(format: "%0.1f", localTemperature)
  }

  var body: some View {
    VStack {
      Text("Settings")
        .font(.title)
      Text("Changing any of these setting will reset the current chat.")
        .font(.callout)
      Form {
        Section("Model Instructions") {
          TextEditor(text: $localInstructions)
        }
        Section("Temperature") {
          Toggle(isOn: $customTemperature) {
            Text("Custom Temperature")
          }
          HStack {
            Slider(value: $localTemperature, in: 0.0...1.0, step: 0.05)
            Text(formattedTemperatre)
          }
          .opacity(customTemperature ? 1.0 : 0.0)
        }
        Section("Sampling") {
          Toggle(isOn: $useGreedy) {
            Text("Use Greedy Sampling")
          }
        }
      }
      .onAppear {
        localInstructions = instruction ?? ""
        localTemperature = temperature ?? 0.2
      }
      .onChange(of: localInstructions) {
        if localInstructions.isEmpty {
          instruction = nil
        } else {
          instruction = localInstructions
        }
      }
      .onChange(of: localTemperature) {
        temperature = localTemperature
      }
    }
  }
}

#Preview {
  @Previewable @State var instructions: String? = ""
  @Previewable @State var customTemperature: Bool = false
  @Previewable @State var temperature: Double?
  @Previewable @State var useGreedy: Bool = false

  ConfigurationView(
    instruction: $instructions,
    customTemperature: $customTemperature,
    temperature: $temperature,
    useGreedy: $useGreedy
  )
}
