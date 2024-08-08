//
//  AuthError.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/26/24.
//

import Foundation

enum AuthError: Error {
    case emptyFields
    case noGoalSelected
    case invalidEmail
    case invalidPassword
    case invalidName
    case invalidBirthday
    case invalidCredential
    case networkError
    case existingAccount
    case nonexistingAccount
    case authenticationError
    case unexpectedError
    
    var name: String {
        switch self {
        case .emptyFields:
            return "Empty Fields"
        case .noGoalSelected:
            return "No Goal Selected"
        case .invalidEmail:
            return "Invalid Email"
        case .invalidPassword:
            return "Invalid Password"
        case .invalidName:
            return "Invalid Name"
        case .invalidBirthday:
            return "Invalid Birthday"
        case .invalidCredential:
            return "Invalid Account"
        case .networkError:
            return "Network Error"
        case .existingAccount:
            return "Existing Account"
        case .nonexistingAccount:
            return "Nonexisting Account"
        case .authenticationError:
            return "Authentication Error"
        case .unexpectedError:
            return "Unexpected Error"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .emptyFields:
            return "Please make sure all fields are completed."
        case .noGoalSelected:
            return "Please make sure you select one goal you want to achieve with the app."
        case .invalidEmail:
            return "Please make sure to use a valid email to sign up with. Make sure your email ends in a valid domain and is currently active."
        case .invalidPassword:
            return "Please make sure to use a valid password to sign up with. Make sure the password is at least 8 characters long, has 1 captial and lowercase letter, number, and special character."
        case .invalidName:
            return "Please make sure you enter your full name."
        case .invalidBirthday:
            return "Please make sure you are at least 13 years old before creating an account, or use the help of a parent."
        case .invalidCredential:
            return "The account you used is invalid. Please try again or use a different account."
        case .networkError:
            return "Please make sure to check your internet connection before authenticating."
        case .existingAccount:
            return "The email you used is already linked to an existing account. Please sign in using it or try another email."
        case .nonexistingAccount:
            return "The email you used is not linked to an existing account. Please sign up using it or try another email."
        case .authenticationError:
            return "There was a problem authenticating your account. Please make sure your fields are valid and correctly filled."
        case .unexpectedError:
            return "An unexpected error occured. Please try again."
        }
    }
    
}
