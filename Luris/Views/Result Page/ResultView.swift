import SwiftUI
import Foundation
import UIKit
import Alamofire
import Photos
import SDWebImage

struct ResultView: View {
    
    @State var resultImage: UIImage?
    @State var imageData: UIImage?
    
    var operationType: OperationType
    
    @Environment(\.presentationMode) var dismiss
    
    @State private var CPicker = UIColor.clear
    @StateObject private var counter = CoinCounter()
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                if let resultImage = resultImage {
                    Image(uiImage: resultImage)
                        .resizable()
                        .scaledToFit()
                        .background(Color(uiColor: CPicker))
                        .frame(maxHeight: .infinity)
                }
                
                Spacer()

                if operationType == OperationType.RemoveBackground {
                    HStack(spacing: 15) {
                        Button{
                            CPicker = .clear
                        } label: {
                            Image("Transparent")
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                        
                        Button{
                            CPicker = .white
                        } label: {
                            Rectangle().fill(.white)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                        
                        ColorPicker("", selection: Binding(
                            get: {
                                Color(uiColor: self.CPicker)
                            },
                            set: { newValue in
                                self.CPicker = UIColor(newValue)
                            }
                        )) .scaleEffect(CGSize(width: 1.4, height: 1.4)) .labelsHidden()
                    }
                }
                
                Button("Save Image") {
                    if let resultImage = resultImage {
                        addBackgroundToImage(image: resultImage, color: CPicker) { result in
                            switch result {
                            case .success(_):
                                saveImage()
                            case .failure(let error):
                                print("Error: \(error)")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(.orange)
                .clipShape(Capsule())
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                
            }
            .padding()
            
            .navigationTitle(
                Text(entitlementManager.hasPro ? "" : "\(counter.coins) Coins")
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationBarItems(leading: Button(action: {
                
            }) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .onTapGesture {
                        dismiss.wrappedValue.dismiss()
                    }
            }, trailing: Button(action: {}, label: {
                
            }))
            .foregroundStyle(.primary)
        }
    }
    
    func addBackgroundToImage(image: UIImage, color: UIColor, completion: @escaping (Result<UIImage, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let size = image.size
            UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            UIRectFill(rect)
            image.draw(in: rect, blendMode: .normal, alpha: 1.0)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let newImage = newImage {
                DispatchQueue.main.async {
                    completion(.success(newImage))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "com.example.addBackgroundToImage", code: -1, userInfo: nil)))
                }
            }
        }
    }
    
    func saveImage() {
        guard let image = resultImage else { return }
        guard let pngData = image.pngData() else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: pngData, options: nil)
            }) { success, error in
                if success {
                    print("Image saved successfully to the photo gallery.")
                } else if let error = error {
                    print("Error saving image to the photo gallery: \(error)")
                } else {
                    print("Unknown error occurred.")
                }
            }
        }
    }

}

#Preview {
    ResultView(operationType: .Reimagine)
}
