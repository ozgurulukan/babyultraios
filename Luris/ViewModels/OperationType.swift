import Foundation
import SwiftUI
import Alamofire

@Observable class Operation {
    
    // Done
    func reimagineImage(`var` image: UIImage?, result: @escaping (UIImage?) -> Void) {
        
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key" : Constants().API_KEY
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "image_file", fileName: "imageName.jpg", mimeType: "image/jpeg")
        }, to: "https://clipdrop-api.co/reimagine/v1/reimagine", headers: headers)
        .responseData(queue: .global()) { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(responseString)")
                    } else {
                        print("Failed to convert response data to UIImage")
                    }
                }
            case .failure(let error):
                print("Upload failed with error: \(error)")
            }
            
        }
    }

    // Done
    func Upscaling(`var` image: UIImage?, widthData: CLong, height: CLong, result: @escaping (UIImage?) -> Void) {
        
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        AF.upload(
            
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    imageData,
                    withName: "image_file",
                    fileName: "car.jpg",
                    mimeType: "image/jpeg"
                )
                
                if let widthData = String(widthData).data(using: .utf8) {
                    multipartFormData.append(widthData, withName: "target_width")
                }
                
                if let heightData = String(height).data(using: .utf8) {
                    multipartFormData.append(heightData, withName: "target_height")
                }
                
            },
              to: "https://clipdrop-api.co/image-upscaling/v1/upscale",
              headers: headers
        )
        .responseData(queue: .global()) { res in
            
            switch res.result {
                
            case .success(let data):
                
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        return result(image)
                    }
                } else {
                    print("Failed to convert response data to UIImage")
                }
                
            case .failure(let error):
                print("Upload failed with error: \(error)")
                return result(nil)
            }
        }
    }
    
    // Done - Background Pending
    func RemoveBackground(`var` image: UIImage?, result: @escaping (UIImage?) -> Void) {
        
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key" : Constants().API_KEY
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "image_file", fileName: "imageName.jpg", mimeType: "image/jpeg")
        }, to: "https://clipdrop-api.co/remove-background/v1", headers: headers)
        .responseData(queue: .global()) { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(responseString)")
                    } else {
                        print("Failed to convert response data to UIImage")
                    }
                }
            
            case .failure(let error):
                print("Upload failed with error: \(error)")
            }
            
        }
    }
    
    // Done
    func RemoveText(`var` image: UIImage?, result: @escaping (UIImage?) -> Void) {
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "image_file", fileName: "imageName.jpg", mimeType: "image/jpeg")
            }, to: "https://clipdrop-api.co/remove-text/v1", headers: headers)
            .responseData(queue: .global()) { response in
                switch response.result {
                case .success(let data):
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            result(image)
                        }
                    } else {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Server Response: \(responseString)")
                        } else {
                            print("Failed to convert response data to UIImage")
                        }
                    }
                
                case .failure(let error):
                    print("Upload failed with error: \(error)")
                }
                
            }
    }
    
    // Done
    func ReplaceBackground(`var` image: UIImage?, prompt: String, result: @escaping (UIImage?) -> Void) {
       
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    imageData,
                    withName: "image_file",
                    fileName: "car.jpg",
                    mimeType: "image/jpeg"
                )
                
                if let widthData = String(prompt).data(using: .utf8) {
                    multipartFormData.append(widthData, withName: "prompt")
                }
            },
              to: "https://clipdrop-api.co/replace-background/v1",
              headers: headers
        )
        .responseData(queue: .global()) { res in
            switch res.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(responseString)")
                    } else {
                        print("Failed to convert response data to UIImage")
                    }
                }
                
            case .failure(_):
                print("Upload failed")
            }
        }
    }
    
    // Done
    func SketchToImage(`var` image: UIImage?, prompt: String, result: @escaping (UIImage?) -> Void){
       
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    imageData,
                    withName: "sketch_file",
                    fileName: "car.jpg",
                    mimeType: "image/jpeg"
                )
                
                if let widthData = String(prompt).data(using: .utf8) {
                    multipartFormData.append(widthData, withName: "prompt")
                }
            },
            to: "https://clipdrop-api.co/sketch-to-image/v1/sketch-to-image",
              headers: headers
        )
        .responseData(queue: .global()) { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(responseString)")
                    } else {
                        print("Failed to convert response data to UIImage")
                    }
                }
            
            case .failure(let error):
                print("Upload failed with error: \(error)")
            }
            
        }
    }
    
    // Done
    func TextToImage(text: String, result: @escaping (UIImage?) -> Void) {
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        AF.upload(multipartFormData: { data in
            if let text = String(text).data(using: .utf8) {
                data.append(text, withName: "prompt")
            }
        }, to: "https://clipdrop-api.co/text-to-image/v1", headers: headers)
        .responseData(queue: .global()) { res in
            switch res.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Server Response: \(responseString)")
                    } else {
                        print("Failed to convert response data to UIImage")
                    }
                }
                
            case .failure(_):
                print("Upload failed")
                
            }
        }
    }

    
    func Uncrop(`var` image: UIImage?, left: String, right: String, top: String, bottom: String, result: @escaping (UIImage?) -> Void) {
        
        guard let selectedImage = image, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("No image selected or unable to convert to JPEG")
            result(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": Constants().API_KEY
        ]
        
        AF.upload(
            
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    imageData,
                    withName: "image_file",
                    fileName: "car.jpg",
                    mimeType: "image/jpeg"
                )
                
                if let left = String(left).data(using: .utf8) {
                    multipartFormData.append(left, withName: "extend_left")
                }
                
                if let right = String(right).data(using: .utf8) {
                    multipartFormData.append(right, withName: "extend_right")
                }
                
                if let top = String(top).data(using: .utf8) {
                    multipartFormData.append(top, withName: "extend_up")
                }
                
                if let bottom = String(bottom).data(using: .utf8) {
                    multipartFormData.append(bottom, withName: "extend_down")
                }
            },
              to: "https://clipdrop-api.co/image-upscaling/v1/upscale",
              headers: headers
        )
        .responseData(queue: .global()) { res in
            switch res.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        result(image)
                    }
                } else {
                    if let _ = String(data: data, encoding: .utf8) {
                        print("Server Response")
                    } else {
                        print("Failed to convert response data")
                    }
                }
                
            case .failure(let error):
                print("Upload failed with error: \(error)")
            }
        }
    }
}
