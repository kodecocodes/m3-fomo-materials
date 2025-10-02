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
import FoundationModels

struct TranscriptView: View {
  @Binding var session: LanguageModelSession

  let instructionsColor = Color.green.mix(with: .white, by: 0.5)
  let promptColor = Color.blue.mix(with: .white, by: 0.5)
  let responseColor = Color.gray.mix(with: .white, by: 0.5)
  let toolCallColor = Color.yellow.mix(with: .white, by: 0.5)
  let toolOutputColor = Color.orange.mix(with: .white, by: 0.5)
  let defaultColor = Color.gray.mix(with: .white, by: 0.2)

  var body: some View {
    Text("Session Transcript")
      .font(.title)
    ScrollView {
      ForEach(session.transcript) { entry in
        switch entry {
        case .instructions(let instructions):
          TranscriptEntryView(text: instructions.description, color: instructionsColor)
        case .prompt(let prompt):
          TranscriptEntryView(
            text: prompt.description,
            color: promptColor
          )
        case .response(let response):
          TranscriptEntryView(
            text: response.description,
            color: responseColor
          )
        case .toolCalls(let toolCall):
          TranscriptEntryView(
            text: toolCall.description,
            color: toolCallColor
          )
        case .toolOutput(let toolOutput):
          TranscriptEntryView(
            text: toolOutput.description,
            color: toolOutputColor
          )
        default:
          TranscriptEntryView(
            text: entry.description,
            color: defaultColor
          )
        }
      }
    }
  }
}

#Preview {
  let session = LanguageModelSession(instructions: "Sample instruction")
  TranscriptView(
    session: .constant(session)
  )
}
