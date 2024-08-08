//
//  LoginView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/22/24.
//

import SwiftUI
import FirebaseAuth
import LocalAuthentication
import GoogleSignIn

struct LoginView: View {
    
    @EnvironmentObject var habitat: Habitat
    @State private var email = String()
    @State private var password = String()
    @State private var uid = String()
    @StateObject private var viewModel = LoginViewModel()
    
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
                    Text("admin")
                        .foregroundStyle(.white)
                        .font(.title)
                        .bold()
                }
                EmailPasswordView(email: $email, password: $password)
                    .environmentObject(habitat)
                ProviderLoginView()
                    .environmentObject(habitat)
            }
        }
        .onTapGesture {
            self.hideKeyboard()
        }
        .onAppear {
//            viewModel.uploadToFirestore()
            if let user = Auth.auth().currentUser {
                let context = LAContext()
                var error: NSError?

                guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                    print(error?.localizedDescription ?? "Can't evaluate policy")
                    return
                }
                Task {
                    do {
                        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Use \(context.biometryType == .faceID ? "Face ID":"Touch ID") to log into your account")
                        viewModel.getUser(docId: user.uid) { result in
                            switch result {
                            case .success(let userProfile):
                                habitat.user = userProfile
                                habitat.appScene = .home
                            case .failure(let error):
                                viewModel.authError = error
                                viewModel.isError = true
                            }
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

fileprivate struct EmailPasswordView: View {
    
    @EnvironmentObject var habitat: Habitat
    @Binding var email: String
    @Binding var password: String
    @FocusState private var focusedField: LoginField?
    @State private var hidden = true
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 5) {
                TextField("email", text: $email)
                    .focused($focusedField, equals: .emailAddress)
                    .padding()
                    .frame(maxWidth: 300, maxHeight: 50)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .tint(.orange)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                ZStack(alignment: .trailing) {
                    if hidden {
                        SecureField("password", text: $password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 50)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                            .font(.body)
                            .textInputAutocapitalization(.never)
                            .tint(.orange)
                            .textContentType(.password)
                            .submitLabel(.done)
                    } else {
                        TextField("password", text: $password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 50)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                            .font(.body)
                            .textInputAutocapitalization(.never)
                            .tint(.orange)
                            .textContentType(.password)
                            .submitLabel(.done)
                    }
                    Button {
                        hidden.toggle()
                    } label: {
                        Image(systemName: "eye\(hidden ? ".slash" :"").fill")
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }
                    
                }
            }
            .onSubmit {
                switch focusedField {
                    case .emailAddress:
                        focusedField = .password
                    default:
                        print("")
                }
            }
            VStack {
                Button(action: {
                    viewModel.email = self.email
                    viewModel.password = self.password
                    if !viewModel.email.isEmpty && !viewModel.password.isEmpty {
                        let isValid = viewModel.validate()
                        if isValid == nil {
                            viewModel.isExisting { result in
                                switch result {
                                case .success:
                                    viewModel.toOAuth { result in
                                        switch result {
                                        case .success(let credential):
                                            viewModel.signIn(with: credential) { result in
                                                switch result {
                                                case .success(let user):
                                                    habitat.user = user
                                                    habitat.appScene = .home
                                                case .failure(let error):
                                                    viewModel.authError = error
                                                    viewModel.isError = true
                                                }
                                            }
                                        case .failure(let error):
                                            viewModel.authError = error as? AuthError
                                            viewModel.isError = true
                                        }
                                    }
                                case .failure(let failure):
                                    viewModel.authError = failure
                                    viewModel.isError = true
                                }
                            }
                        } else {
                            viewModel.authError = isValid
                            viewModel.isError = true
                        }
                    } else {
                        viewModel.authError = .emptyFields
                        viewModel.isError = true
                    }
                }, label: {
                    Text("login")
                        .font(.body)
                        .fontWeight(.semibold)
                        .padding()
                        .padding(.horizontal, 30)
                        .foregroundStyle(.black)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                })
                Button(action: {
                    habitat.user.email = email
                    habitat.appScene = .resetPassword
                }, label: {
                    Text("forgot your password?")
                        .foregroundStyle(.white)
                        .font(.body)
                })
            }
        }
        .alert(viewModel.authError?.name ?? "", isPresented: $viewModel.isError, actions: {
            Button {} label: {
                Text("Ok")
            }
            
        }, message: {
            Text(viewModel.authError?.localizedDescription ?? "")
        })
    }
    
}

fileprivate struct ProviderLoginView: View {
    
    @EnvironmentObject var habitat: Habitat
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        HStack {
            Button(action: {
                
            }, label: {
                Image(systemName: "applelogo")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .frame(maxHeight: 20)
                    .padding()
                    .padding(.horizontal, 30)
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
            })
            Button(action: {
                viewModel.signInWithGoogle { result in
                    print(result)
                    switch result {
                    case .success(let user):
                        habitat.user = user
                        habitat.appScene = .home
                    case .failure(let error):
                        viewModel.authError = error
                        viewModel.isError = true
                    }
                }
            }, label: {
                Image("googlelogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .frame(maxHeight: 20)
                    .padding()
                    .padding(.horizontal, 30)
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
            })
        }
        .alert(viewModel.authError?.name ?? "", isPresented: $viewModel.isError, actions: {
            Button {} label: {
                Text("Ok")
            }
            
        }, message: {
            Text(viewModel.authError?.localizedDescription ?? "")
        })
    }
}

fileprivate enum LoginField {
    case emailAddress
    case password
}

#Preview {
    LoginView()
        .environmentObject(Habitat())
        .preferredColorScheme(.light)
}
