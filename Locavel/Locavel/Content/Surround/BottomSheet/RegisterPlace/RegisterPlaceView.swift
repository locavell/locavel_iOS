//
//  RegisterPlaceView.swift
//  Locavel
//
//  Created by 김의정 on 8/16/24.
//

import Foundation
import SwiftUI

import PhotosUI

struct RegisterPlaceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // 장소 등록에 필요한 상태 변수들
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var telephoneNumber: String = ""
    @State private var selectedCategory: String = ""
    @State private var rating: Int = 0
    @State private var isSubmitting: Bool = false // 등록 중 상태 관리
    
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingPhotoPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 상단의 사진 등록 버튼과 이미지
                        ZStack(alignment: .bottom) {

                            Button(action: {
                                isShowingPhotoPicker = true
                            }) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .overlay(Text("사진 등록").foregroundColor(.white).padding(8), alignment: .bottom)
                                }
                            }
                            .padding(.top, 20)
                            .sheet(isPresented: $isShowingPhotoPicker) {
                                PhotoPicker(selectedImage: $selectedImage)
                            }
                            
                        }
                        .padding()

                        // 장소명 입력 필드
                        VStack(alignment: .leading) {
                            Text("장소명 (필수)")
                                .font(.headline)
                            TextField("장소 이름을 말해주세요", text: $name)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        // 별점 입력
                        RatingView(rating: $rating)

                        // 카테고리 선택
                        CategorySelectionView(selectedCategory: $selectedCategory)

                        // 위치 확인하기 필드
                        VStack(alignment: .leading) {
                            Text("위치 확인하기")
                                .font(.headline)
                            TextField("주소 입력", text: $address)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // 전화번호 입력 필드
                        VStack(alignment: .leading) {
                            Text("전화번호")
                                .font(.headline)
                            TextField("전화번호 입력", text: $telephoneNumber)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        Spacer()
                            .frame(height: 20)
                    }
                    .padding()
                }
                
                // 하단 고정된 버튼
                VStack {
                    Spacer()
                    Button(action: {
                        submitPlace() // 등록하기 로직 호출
                    }) {
                        Text(isSubmitting ? "등록 중..." : "등록하기")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 140, height: 40)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(50)
                            .padding(.horizontal)
                    }
                    .disabled(isSubmitting) // 요청 중일 때 버튼 비활성화
                }
            }
            .navigationTitle("새로 등록하기")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
            })
        }
    }

    // 등록하기 버튼을 눌렀을 때 호출되는 함수
    private func submitPlace() {
        guard !name.isEmpty, !address.isEmpty, !selectedCategory.isEmpty, rating > 0 else {
            print("모든 필드를 채워주세요.")
            return
        }

        isSubmitting = true

        let boundary = UUID().uuidString
        let url = URL(string: "https://api.locavel.site/api/places")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(TokenManager.shared.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // JSON 데이터 추가 (placeDTO)
        let placeDTO: [String: Any] = [
            "name": name,
            "address": address,
            "category": selectedCategory.lowercased(),
            "telephoneNumber": telephoneNumber,
            "rating": rating
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: placeDTO, options: [])
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"placeDTO\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(jsonData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            print("Error encoding JSON: \(error)")
            isSubmitting = false
            return
        }

        // 이미지 파일 추가 (placeImgUrls)
        let imageKey = "placeImgUrls"
        let imageFileName = "image.jpg"
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"\(imageFileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
            }

            if let error = error {
                print("Error during request: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                if (200...299).contains(httpResponse.statusCode) {
                    print("Request successful")
                } else {
                    print("Request failed with status code: \(httpResponse.statusCode)")
                }
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            DispatchQueue.main.async {
                // 성공적으로 등록 후, 화면을 닫거나 알림 표시
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    self?.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}
