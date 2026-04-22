import SwiftUI
import Photos

struct Upscaling: View {
    let image: UIImage?
    let template: TemplateItem

    @State private var selectedRatio: String = "1:1"
    @State private var isResult = false
    @State private var resultURL: String?
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    private let aspectRatios = ["1:1", "2:1", "4:3"]

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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(aspectRatios, id: \.self) { ratio in
                                Button {
                                    withAnimation(.snappy) { selectedRatio = ratio }
                                } label: {
                                    Text(ratio)
                                        .font(.system(size: 16, weight: selectedRatio == ratio ? .semibold : .regular))
                                        .foregroundStyle(selectedRatio == ratio ? .white : Bubsie.textSecondary)
                                        .padding()
                                        .frame(width: 100, height: 80)
                                        .background(selectedRatio == ratio ? Bubsie.accent : Bubsie.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                        }
                    }
                    .scrollClipDisabled()
                }
                .padding()
            }
            .navigationTitle("Upscale Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear { startUpscale() }
        }
        .preferredColorScheme(.dark)
    }

    private func startUpscale() {
        guard !isSubmitting else { return }
        guard let image = image else {
            errorMessage = "No image selected"
            return
        }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let result = try await BubsieAPI.shared.uploadAndTransform(
                    image: image,
                    template: template,
                    aspectRatio: selectedRatio
                )
                await MainActor.run {
                    resultURL = result.resultUrl
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}