//
//  LoginViewModel.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/26/24.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import LocalAuthentication
import GoogleSignIn

class LoginViewModel: ObservableObject {
    @Published var name = String()
    @Published var email = String()
    @Published var password = String()
    @Published var isSigningUp = false
    @Published var isError = false
    @Published var authError: AuthError?
    
    func validate() -> AuthError? {
        if !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}") .evaluate(with: email){
            return .invalidEmail
        }
        if !NSPredicate(format:"SELF MATCHES %@", "^(?=.*[A-Z])(?=.*[!@#$&*])(?=.*[0-9]).{8,}$") .evaluate(with: password){
            return .invalidPassword
        }
        return nil
    }
    func toOAuth(completion: (Result<AuthCredential, Error>) -> ()) {
        if let error = validate() {
            completion(.failure(error))
            return
        }
        completion(.success(EmailAuthProvider.credential(withEmail: email, password: password)))
    }
    func isExisting(completion: @escaping((Result<AuthError, AuthError>)) -> ()) {
        Auth.auth().fetchSignInMethods(forEmail: email) { providers, error in
            if let error = error {
                completion(.failure(self.errorHandler(error)))
                return
            }
            if let providers = providers, !providers.isEmpty {
                completion(.success(.existingAccount))
            } else {
                completion(.success(.nonexistingAccount))
            }
        }
    }
    func signIn(with credential: AuthCredential, completion: @escaping((Result<User, AuthError>) -> ())) {
        isSigningUp = false
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(self.errorHandler(error)))
                return
            }
            guard let authResult = authResult else {
                completion(.failure(AuthError.unexpectedError))
                return
            }
            self.getUser(docId: authResult.user.uid) { result in
                completion(result)
            }
        }
    }
    func signUp(with credential: AuthCredential, completion: @escaping((Result<User, AuthError>) -> ())) {
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(self.errorHandler(error)))
                return
            }
            guard let authResult = authResult else {
                completion(.failure(AuthError.unexpectedError))
                return
            }
            self.createUser(with: authResult) { result in
                completion(result)
            }
        }
    }
    func createUser(with result: AuthDataResult, completion: @escaping((Result<User, AuthError>) -> ())) {
        Firestore.firestore().collection("Users").document(result.user.uid).setData(["name": result.user.displayName ?? "", "email": result.user.email ?? "", "write": false]) { error in
            if let error = error {
                print(self.errorHandler(error))
                completion(.failure(self.errorHandler(error)))
                return
            }
            Firestore.firestore().collection("Users").document(result.user.uid).getDocument { documentSnapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let documentSnapshot = documentSnapshot {
                    let email = documentSnapshot.get("email") as! String
                    completion(.success(User(name: result.user.displayName ?? "", email: email, uid: result.user.uid, canWrite: false)))
                }
            }
        }
    }
    func errorHandler(_ error: Error) -> AuthError {
        print(error.localizedDescription)
        switch error {
        default:
            return .unexpectedError
        }
    }
    func getUser(docId: String, completion: @escaping(Result<User, AuthError>) -> ()) {
        Firestore.firestore().collection("Users").document(docId).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(self.errorHandler(error)))
                return
            }
            if let documentSnapshot = documentSnapshot {
                guard let email = documentSnapshot.get("email") as? String else {
                    completion(.failure(.unexpectedError))
                    return
                }
                guard let name = documentSnapshot.get("name") as? String else {
                    completion(.failure(.unexpectedError))
                    return
                }
                guard let write = documentSnapshot.get("write") as? Bool else {
                    completion(.failure(.unexpectedError))
                    return
                }
                completion(.success(User(name: name, email: email, uid: docId, canWrite: write)))
            }
        }
    }
    func signInWithGoogle(completion: @escaping(Result<User, AuthError>) -> ()) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                if let error = error {
                    print(error.localizedDescription)
                    completion(.failure(self.errorHandler(error)))
                    return
                }
                if let user = user {
                    self.createGoogleCredential(user: user) { result in
                        switch result {
                        case .success(let credential):
                            self.signIn(with: credential) { result in
                                switch result {
                                case .success(let user):
                                    completion(.success(user))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            let config = GIDConfiguration(clientID: clientID)
            
            GIDSignIn.sharedInstance.configuration = config
            
            guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let signedUser = result?.user {
                    self.createGoogleCredential(user: signedUser) { result in
                        switch result {
                        case .success(let credential):
                            Auth.auth().fetchSignInMethods(forEmail: signedUser.profile?.email ?? "") { providers, error in
                                if let error = error {
                                    print(error.localizedDescription)
                                    completion(.failure(self.errorHandler(error)))
                                    return
                                }
                                if let providers = providers, !providers.isEmpty {
                                    self.signIn(with: credential) { result in
                                        switch result {
                                        case .success(let user):
                                            completion(.success(user))
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                    }
                                } else {
                                    self.signUp(with: credential) { result in
                                        switch result {
                                        case .success(let user):
                                            completion(.success(user))
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    func createGoogleCredential(user: GIDGoogleUser?, completion: @escaping(Result<AuthCredential, AuthError>) -> ()){
        guard let idToken = user?.idToken, let accessToken = user?.accessToken else {
            completion(.failure(.unexpectedError))
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
        completion(.success(credential))
    }
//    func uploadToFirestore() {
//        let instructions = allInstructions.split(separator: "Image")
//        print("bro")
//        for instruction in instructions {
//            let instruct = instruction.split(separator: "    ")
//            if instruct.count > 1 {
//                let docId = instruct[1].split(separator: "\n")[0]
//                if instruct.count > 2 {
//                    if let check = instruct[2].split(separator: "\n").last, check == "Instruction 1" {
//                        let instruction1 = instruct[3].split(separator: "\n")[0]
//                        print(instruction1)
//                        if instruct[3] != instruct.last! {
//                            if let instruction2 = instruct.last?.trimmingCharacters(in: .whitespacesAndNewlines) {
//                                print(instruction2)
//                                Firestore.firestore().collection("Meals").document(String(docId)).setData(["instructions": [String(instruction1), String(instruction2)]], merge: true) { error in
//                                    if let error = error {
//                                        print(error.localizedDescription)
//                                    }
//                                }
//                            }
//                        } else {
//                            Firestore.firestore().collection("Meals").document(String(docId)).setData(["instructions": [String(instruction1)]], merge: true) { error in
//                                if let error = error {
//                                    print(error.localizedDescription)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//                Firestore.firestore().collection("Meals").getDocuments { querySnapshot, error in
//                    if let error = error {
//                        return
//                    }
//                    if let documents = querySnapshot?.documents, !documents.isEmpty {
//                        for document in documents {
//                            let pathReference = Storage.storage().reference(withPath: "/resizedMeals")
//                            pathReference.child("/\(document.documentID).png").getData(maxSize: 1 * 2000 * 2000) { data, error in
//                              if let error = error {
//                                  //print(error.localizedDescription)
//                                  print(document.documentID)
//                              } else {
//                                  guard let data = data else {
//                                      print(document.documentID)
//                                      return
//                                  }
//                              }
//                            }
//                        }
//                    }
//                }
//    }
}
