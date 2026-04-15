//
//  Upscaling.swift
//  Luris
//
//  Created by Ozgur Ulukan on 12/07/24.
//

import SwiftUI
import Shimmer

struct UpscaleSize: Identifiable {
    var id: UUID = .init()
    var multiplier: CLong
    var isCustom: Bool = false
}

var sampleUpscaleSize : [UpscaleSize] = [
    .init(multiplier: 2),
    .init(multiplier: 4),
    .init(multiplier: 6),
    .init(multiplier: 8),
    .init(multiplier: 10),
]

struct Upscaling: View {
    
    @State private var isSelected: UpscaleSize = .init(multiplier: 2)
        
    @State var image: UIImage?
    
    var operation: OperationType
    
    @State private var vm = Operation()
    
    @State private var isResult = false
    
    @State private var isSave = false
    
    @State private var processedImage: UIImage?
    @State private var isHavingResult = true

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
                        .foregroundStyle(.black)
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(sampleUpscaleSize, id: \.id) {
                            size in
                            
                            Button {
                                withAnimation(.snappy) {
                                    isSelected = size
                                    upscale(multiple: size.multiplier)
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        if size.isCustom {
                                            VStack(spacing: 10) {
                                                Text("\(size.multiplier)x")
                                                        .font(.system(size: 16))
                                                Image(systemName: "pencil.line")
                                            }
                                        } else {
                                            Text("\(size.multiplier)x")
                                                .font(.system(size: 16))
                                        }
                                    }
                                }
                                .multilineTextAlignment(.leading)
                                .fontWeight(isSelected.multiplier == size.multiplier ? .semibold : .regular)
                                .foregroundStyle(isSelected.multiplier == size.multiplier ? .white : Color("Text"))
                                .padding()
                                .frame(width: 100, height: 80)
                                .background(isSelected.multiplier == size.multiplier ? .orange : .gray.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 20))
                            }
                            .foregroundColor(.primary)
                            
                        }
                    }

                }
                .scrollClipDisabled()
            }
            .padding()
            .onAppear() {
                upscale(multiple: isSelected.multiplier)
            }
            .navigationTitle(
                Text("Upscale Image")
            )
            
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
    
    func upscale(multiple: CLong) {
        isResult = false
        if let image = image {
            let width = (image.size.width * CGFloat(multiple)) > 4096 ? 4096 : (image.size.width * CGFloat(multiple))
            
            let height = (image.size.height * CGFloat(multiple)) > 4096 ? 4096 : (image.size.height * CGFloat(multiple))

            vm.Upscaling(var: image, widthData: CLong(width), height: CLong(height)) { resImage in
                
                if resImage != nil {
                    processedImage = resImage
                    print("Success")
                    isResult.toggle()
                } else {
                    print("Error")
                }
            }
        }
    }
    
    
}

#Preview {
    Upscaling(operation: .Upscaling)
}
