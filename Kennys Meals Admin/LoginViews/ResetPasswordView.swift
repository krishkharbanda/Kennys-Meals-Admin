//
//  ResetPasswordView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/25/24.
//

import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    
    @EnvironmentObject var habitat: Habitat
    @State private var isError = false
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea(.all)
            VStack(spacing: 50) {
                VStack {
                    Image("kennyslogo-card")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                        .frame(maxHeight: 100)
                        .shadow(radius: 5, x: 0, y: 2)
                    Text("reset password")
                        .foregroundStyle(.white)
                        .font(.title)
                        .bold()
                }
                VStack {
                    TextField("email", text: $habitat.user.email)
                        .padding()
                        .frame(maxWidth: 300, maxHeight: 50)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .tint(.orange)
                }
                VStack {
                    Button(action: {
                        Auth.auth().sendPasswordReset(withEmail: habitat.user.email) { error in
                            if let error = error {
                                print("Error:", error.localizedDescription)
                                isError = true
                                return
                            }
                            isSuccess = true
                        }
                    }, label: {
                        Text("send")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding()
                            .padding(.horizontal, 30)
                            .foregroundStyle(.black)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                    })
                    Button(action: {
                        habitat.appScene = .login
                    }, label: {
                        Text("< back")
                            .foregroundStyle(.white)
                            .font(.body)
                    })
                }
            }
        }
        .onTapGesture {
            self.hideKeyboard()
        }
        .alert("Unexpected Error", isPresented: $isError, actions: {
            Button {} label: {
                Text("Ok")
            }
            
        }, message: {
            Text("Please try again or a different email.")
        })
        .alert("Success!", isPresented: $isSuccess, actions: {
            Button {
                habitat.appScene = .login
            } label: {
                Text("Ok")
            }
            
        }, message: {
            Text("Please check your email for a password reset link.")
        })
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(Habitat())
        .preferredColorScheme(.light)
}
