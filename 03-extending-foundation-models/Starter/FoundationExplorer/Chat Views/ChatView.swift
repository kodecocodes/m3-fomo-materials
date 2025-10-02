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
  @State private var showConfig = false
  @State private var session = LanguageModelSession()
  @State private var promptInstructions: String?
  @State private var customTemperature = false
  @State private var modelTemperature: Double?
  @State private var useGreedy = false
  @State private var showTranscript = false
  @State private var showFoodMenu = false

  struct MenuView: View {
    @Binding var showTranscript: Bool
    @Binding var showFoodMenu: Bool

    var body: some View {
      Menu {
        Button {
          showTranscript = true
        } label: {
          Label {
            Text("Session Transcript")
          } icon: {
            Image(systemName: "text.page")
          }
        }
        Button {
          showFoodMenu = true
        } label: {
          Label {
            Text("Dining Menu")
          } icon: {
            Image(systemName: "menucard")
          }
        }
      } label: {
        Image(systemName: "menucard.fill")
      }
    }
  }

  @ToolbarContentBuilder private var appToolbar: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      MenuView(showTranscript: $showTranscript, showFoodMenu: $showFoodMenu)
      .sheet(isPresented: $showTranscript) {
        TranscriptView(session: $session)
      }
      .sheet(isPresented: $showFoodMenu) {
        FoodMenuView()
      }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        showConfig = true
      } label: {
        Image(systemName: "gear")
          .foregroundStyle(.primary)
      }
      .sheet(isPresented: $showConfig) {
        ConfigurationView(
          instruction: $promptInstructions,
          customTemperature: $customTemperature,
          temperature: $modelTemperature,
          useGreedy: $useGreedy
        )
      }
    }
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
          .onChange(of: promptInstructions) { oldValue, newValue in
            print("Instructions changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            resetChatHistory()
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
        appToolbar
      }
    }
  }

  private func resetChatHistory() {
    messages = []
    session = LanguageModelSession(instructions: promptInstructions)
  }

  private func addMessage(_ message: String, isFromUser: Bool, animate: Bool = true) {
    let newMessage = Message(
      id: UUID(),
      text: message,
      isFromUser: isFromUser,
      timestamp: Date()
    )

    if animate {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
        messages.append(newMessage)
      }
    } else {
      messages.append(newMessage)
    }
  }

  private func removeLastMessage() {
    messages.removeLast()
  }

  private func sendMessage() async {
    guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    // Append user message
    addMessage(messageText, isFromUser: true)

    let temperature = customTemperature ? modelTemperature : nil
    let samplingMode = useGreedy ? GenerationOptions.SamplingMode.greedy : nil
    let options = GenerationOptions(sampling: samplingMode, temperature: temperature)
    let stream = session.streamResponse(to: messageText, options: options)
    messageText = ""

    // 1
    addMessage("", isFromUser: false)
    // 2
    do {
      // 3
      for try await partialResponse in stream {
        // 4
        removeLastMessage()
        // 5
        addMessage(partialResponse.content, isFromUser: false, animate: false)
      }
    }
    catch LanguageModelSession.GenerationError.guardrailViolation {
      addMessage(
        """
        The system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
        """,
        isFromUser: false
      )
    }
    catch LanguageModelSession.GenerationError.exceededContextWindowSize {
      await summarizeChat()
    }
    catch {
      // 6
      addMessage(error.localizedDescription, isFromUser: false)
    }
  }

  func summarizeChat() async {
    // 1
    var allText = ""
    // 2
    for entry in session.transcript {
      // 3
      switch entry {
      case .prompt(let prompt):
        allText += prompt.description + "\n"
      case .response(let response):
        allText += response.description + "\n"
      default:
        allText += "\n"
      }
    }
    // 4
    addMessage("Context windows exceeded. Summarizing Chat", isFromUser: false)

    let summarySession = LanguageModelSession(instructions: "Summarize all text presented to the model.")
    let summarizedText = try? await summarySession.respond(to: allText).content

    // 1
    if let summarizedText = summarizedText {
      // 2
      resetChatHistory()
      addMessage(summarizedText, isFromUser: false)
      // 3
      session = LanguageModelSession(instructions: promptInstructions)
      // 4
      let response = try? await session.respond(to: summarizedText)
      addMessage(response?.content ?? "", isFromUser: false)
    } else {
      // 5
      resetChatHistory()
    }
  }
}

// Preview
struct ChatView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView()
  }
}
