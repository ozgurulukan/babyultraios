import SwiftUI
import Shimmer

struct Cards: Identifiable {
    var id: UUID = .init()
    var title: String
    var caption: String
    var image: String
    var custom: Bool = false
}

var sampleBackgrounds: [Cards] = [
    .init(title: "", caption: "", image: "", custom: true),
    .init(title: "Metropolis Magic", caption: "Replace background with a futuristic, neon-lit metropolis.", image: "Back 1"),
    .init(title: "Coastal Escape", caption: "Replace background with a stunning beach sunset", image: "Back 2"),
    .init(title: "Underwater Adventure", caption: "Replace background with a vibrant coral reef teeming with marine life", image: "Back 3"),
    .init(title: "Forest Fantasy", caption: "Create a mystical forest background with glowing fairies", image: "Back 4"),
    .init(title: "Cosmic Canvas", caption: "Replace background with a swirling nebula in outer space", image: "Back 5"),
    .init(title: "Geometric Galaxy", caption: "Replace background with a vibrant, geometric pattern", image: "Back 6"),
    .init(title: "Noir Nightlife", caption: "Replace background with a vibrant coral reef teeming with marine life", image: "Back 7"),
]

var sampleReimagine: [Cards] = [
    .init(title: "", caption: "", image: "reimagine 1"),
    .init(title: "", caption: "", image: "reimagine 2"),
    .init(title: "", caption: "", image: "reimagine 3"),
    .init(title: "", caption: "", image: "reimagine 4"),
    .init(title: "", caption: "", image: "reimagine 5"),
    .init(title: "", caption: "", image: "reimagine 6"),
]

struct PrompotView: View {
            
    @State var image: UIImage?
    
    var operation: OperationType
    
    @State private var vm = Operation()
    
    @State private var isResult = true
    @State private var isSelection : Cards = sampleBackgrounds[0]
    
    @State private var isSave = false
    
    @State private var processedImage: UIImage?
    
    @State private var isCustom = false
    @Environment(\.presentationMode) var dismiss
    
    @State private var isHavingResult = true
    
    @State private var prompt: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                ZStack(alignment: .bottomTrailing) {
                    
                    if isHavingResult, let processedImage = processedImage  {
                        Image(uiImage: processedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 20))
                    } else {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 20))
                        }
                    }
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.black))
                        .padding(12)
                        .background(.white)
                        .clipShape(Circle())
                        .padding()
                        .onTapGesture {
                            withAnimation(.snappy){
                                isHavingResult.toggle()
                            }
                        }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shimmering(active: !isResult)
                
                if operation == .SketchToImage {
                    
                    TextField("Write Prompt", text: $prompt, axis: .vertical)
                        .padding()
                        .lineLimit(5...10)
                        .multilineTextAlignment(.leading)
                        .background(.gray.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 20))
                    
                    
                    Button("Create Image") {
                        imageProcess()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.orange)
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)

                    
                } else if operation == .ReplaceBackground {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(sampleBackgrounds, id: \.id) { item in
                                Button {
                                    if item.custom {
                                        isCustom.toggle()
                                    } else {
                                        isResult.toggle()
                                        isSelection = item
                                        imageProcess()
                                    }
                                } label: {
                                    if item.custom {
                                        ZStack(alignment: .bottomLeading, content: {
                                            Image(systemName: "pencil.line")
                                                .imageScale(.large)
                                                .frame(width: 100, height: 120)
                                                .background(.gray.opacity(0.1))
                                                .clipShape(.rect(cornerRadius: 20))
                                        })
                                    } else {
                                        ZStack(alignment: .bottomLeading, content: {
                                            Image(item.image)
                                                .resizable()
                                                .scaledToFill()
                                                .overlay(content: {
                                                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                                })
                                            
                                            Text(item.title)
                                                .padding(10)
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                                .fontWeight(.semibold)
                                                .multilineTextAlignment(.leading)
                                        })
                                        .frame(width: 100, height: 120)
                                        .clipShape(.rect(cornerRadius: 20))
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                    .scrollClipDisabled()
                }
            }
            .padding()
            .navigationTitle(
                Text("\(operation.rawValue)")
            )
            
            .sheet(isPresented: $isCustom, onDismiss: {
                imageProcess()
            }, content: {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .onTapGesture {
                                dismiss.wrappedValue.dismiss()
                            }
                    }
                    
                    TextField("Write Prompt", text: $prompt, axis: .vertical)
                        .padding()
                        .lineLimit(5...10)
                        .multilineTextAlignment(.leading)
                        .background(.gray.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 20))
                    
                    Spacer()
                    
                    Button("Create Image") {
                        isSelection.title = prompt
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.orange)
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                }
                .padding([.top, .horizontal])
                .presentationDetents([.height(300)])
            })
            
            .navigationBarBackButtonHidden()
            .navigationDestination(isPresented: $isSave, destination: {
                ResultView(resultImage: processedImage, operationType: operation)
            })
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationBarItems(leading: Button(action: {
                
            }) {
                Image(systemName: "arrow.left")
                    .imageScale(.medium)
            }, trailing: Button(action: {}, label: {
                Text("Save")
                    .onTapGesture {
                        isSave.toggle()
                    }
            }))
            .foregroundStyle(.primary)
        }
    }
    
    func imageProcess() {
        isResult = false
        if let image = image {
            if operation == .ReplaceBackground {
                vm.ReplaceBackground(var: image, prompt: prompt, result: { image in
                    if image != nil {
                        processedImage = image
                        isResult.toggle()
                    } else {
                        print("Error")
                    }
                })
            }
            
            if operation == .SketchToImage {
                vm.SketchToImage(var: image, prompt: prompt, result: { image in
                    if image != nil {
                        processedImage = image
                        isResult.toggle()
                    } else {
                        print("Error")
                    }
                })
            }
            
        }
    }
    
}

#Preview {
    PrompotView(operation: .SketchToImage)
}
