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

struct FoodMenuView: View {
  @State var menu: RestaurantMenu.PartiallyGenerated?
  @State var special: MenuItem?
  
  // 1
  func generateLunchMenu() async {
    // 2
    let session = LanguageModelSession(instructions: "You are a helpful model assisting with generating realistic restaurant menus.")
    // 3
    let prompt = "Create a menu for lunch at a casual dining restaurant"
    // 4
    let streamedResponse = session.streamResponse(to: prompt, generating: RestaurantMenu.self)
    // 5
    do {
      for try await partialResponse in streamedResponse {
        menu = partialResponse.content
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func generateMenuSpecial() async {
    // 1
    let todaysIngredients = ["lamb", "salmon", "duck"]
    // 2
    let specialMealSchema = DynamicGenerationSchema(
      name: "specialmenuitem",
      // 3
      properties: [
        // 4
        DynamicGenerationSchema.Property(
          name: "ingredients",
          // 5
          schema: DynamicGenerationSchema(
            name: "ingredients",
            anyOf: todaysIngredients
          )
        ),
        // 6
        DynamicGenerationSchema.Property(
          name: "name",
          schema: DynamicGenerationSchema(type: String.self)
        ),
        DynamicGenerationSchema.Property(
          name: "description",
          schema: DynamicGenerationSchema(type: String.self)
        ),
        DynamicGenerationSchema.Property(
          name: "price",
          schema: DynamicGenerationSchema(type: Decimal.self)
        )
      ]
    )
    
    // 1
    let schema = try? GenerationSchema(root: specialMealSchema, dependencies: [])
    // 2
    guard let schema = schema else { return }
    // 3
    let session = LanguageModelSession(instructions: "You are a helpful model assisting with generating realistic restaurant menus.")
    let specialPrompt = "Produce a lunch special menu item that is focused on the specified ingredient."
    let response = try? await session.respond(to: specialPrompt, schema: schema)

    let name = try? response?.content.value(String.self, forProperty: "name")
    let ingredients = try? response?.content.value(String.self, forProperty: "ingredients")
    let description = try? response?.content.value(String.self, forProperty: "description")
    let price = try? response?.content.value(Decimal.self, forProperty: "price")
    let specialItem = MenuItem(
      name: name ?? "",
      description: description ?? "",
      ingredients: ingredients == nil ? [] : [ingredients!],
      cost: price ?? 0.0
    )
    
    special = specialItem
  }
  
  var body: some View {
    VStack {
      Button("Generate Lunch Menu") {
        Task {
          await generateLunchMenu()
          await generateMenuSpecial()
        }
      }
      if let special = special {
        MenuItemView(menuItem: special.asPartiallyGenerated())
        Text("Today's Special")
          .font(.title2)
        Divider()
      }
      if let menu = menu {
        if let menuItems = menu.menu {
          ScrollView {
            ForEach(menuItems, id: \.name) { item in
              MenuItemView(menuItem: item)
              Divider()
            }
          }
        }
      }
      Spacer()
    }
    .padding()
  }
}

#Preview {
  FoodMenuView()
}
