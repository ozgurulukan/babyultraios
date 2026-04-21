import SwiftUI

struct PrompotView: View {
    let image: UIImage?
    let template: TemplateItem

    @State private var prompt: String = ""
    @State private var isResult = false
    @State private var resultURL: String?
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                VStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 14))
                            .foregroundStyle(.black)
                            .padding(12)
                            .background(.white)
                            .clipShape(Circle())
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    TextField("Write prompt (optional)...", text: $prompt, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .tint(Bubsie.accent)
                        .lineLimit(3...6)
                        .padding()
                        .background(Bubsie.card)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))

                    Button("Transform") {
                        startTransform()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Bubsie.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left").foregroundStyle(.white)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(isPresented: $isResult) {
                if let url = resultURL {
                    ResultView(resultURL: url, actionType: template.actionType)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func startTransform() {
        guard let image = image else {
            errorMessage = "No image selected"
            return
        }
        Task {
            do {
                let result = try await BubsieAPI.shared.uploadAndTransform(
                    image: image,
                    template: template
                )
                DispatchQueue.main.async {
                    resultURL = result.resultUrl
                    isResult = true
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}