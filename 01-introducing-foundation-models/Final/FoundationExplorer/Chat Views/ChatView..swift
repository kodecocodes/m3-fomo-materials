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

struct ChatView: View {
  @State private var messageText = ""
  @State private var messages: [Message] = []
  @FocusState private var isTextFieldFocused: Bool
  @State private var showAlert = false
  @State private var session = LanguageModelSession()

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Instuctions
        Text("Welcome to Foundation Explorer. Enter a message to begin interacting with the Foundation Model.")
          .font(.title2)
        // Show messages
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(messages) { message in
                MessageBubble(message: message)
                  .id(message.id)
              }

              if session.isResponding {
                TypingIndicator()
                  .transition(.scale)
              }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
          }
          .onChange(of: messages.count) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
              proxy.scrollTo(messages.last?.id, anchor: .bottom)
            }
          }
          .onChange(of: messages.last?.text) { _, _ in
            withAnimation(.easeInOut(duration: 0.1)) {
              proxy.scrollTo(messages.last?.id, anchor: .bottom)
            }
          }
        }
        // Message input
        MessageInputView(
          messageText: $messageText,
          isTextFieldFocused: $isTextFieldFocused,
          sendAction: sendMessage
        )
        .disabled(session.isResponding)
      }
      .navigationTitle("Foundation Explorer")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showAlert = true
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.red)
          }
          .confirmationDialog("Are you sure you want to delete the chat history?", isPresented: $showAlert) {
            Button("Delete Chat History", role: .destructive) {
              resetChatHistory()
            }
          }
        }
      }
    }
  }

  private func resetChatHistory() {
    messages = []
    session = LanguageModelSession()
  }

  private func sendMessage() async {
    guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let newMessage = Message(
      id: UUID(),
      text: messageText,
      isFromUser: true,
      timestamp: Date()
    )

    // Append user message
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      messages.append(newMessage)
    }

    // 1
    var response: String

    // 2
    do {
      // 3
      let modelResponse = try await session.respond(to: messageText)
      response = modelResponse.content
      messageText = ""
    } catch {
      // 4
      response = "An error occurred while processing your message. \(error.localizedDescription)"
    }

    let responseMessage = Message(
      id: UUID(),
      text: response,
      isFromUser: false,
      timestamp: Date()
    )

    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      messages.append(responseMessage)
    }
  }
}

// Preview
struct ChatView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView()
  }
}
