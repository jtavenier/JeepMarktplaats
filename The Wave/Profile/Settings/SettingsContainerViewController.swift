//
//  SettingsContainerViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 2/11/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper
import FBSDKLoginKit
import OneSignal

class SettingsContainerViewController: UIViewController {
    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var fullNameTextField: UITextField!
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmPasswordContainer: UIView!
    
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var giveFeedbackButton: UIButton!

    @IBOutlet weak var userIdLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    var fullName: String!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.roundCorners(radius: 8.0)
        view.clipsToBounds = true
        
        fullNameTextField.text = fullName
        
        if KeychainWrapper.standard.string(forKey: UserInfoKeys.UserPass) == nil {
            categoryLabel.isHidden = true
            passwordContainer.isHidden = true
            confirmPasswordContainer.isHidden = true
        }

        giveFeedbackButton.layer.borderColor = giveFeedbackButton.titleLabel!.textColor.cgColor
        giveFeedbackButton.layer.borderWidth = 1.0

        userIdLabel.text = "User ID: \(Auth.auth().currentUser!.uid)"
        
        saveButton.roundCorners(radius: 8.0)
        saveButton.alpha = 0.0
        
        closeButton.layer.borderColor = closeButton.titleLabel!.textColor.cgColor
        closeButton.layer.borderWidth = 1.0
        closeButton.roundCorners(radius: 8.0)

        view.hideKeyboardWhenTappedAround()
    }
    
    // MARK: - Actions
    
    @IBAction func fullNameTextFieldChanged(_ sender: UITextField) {
        if saveButton.alpha != 1.0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.saveButton.alpha = 1.0
            })
        }
        
        if let text = sender.text {
            if text.characters.count >= 4 {
                fullNameLabel.textColor = .waveGreen
            } else {
                fullNameLabel.textColor = .waveRed
            }
        } else {
            fullNameLabel.textColor = .waveRed
        }
    }
    
    @IBAction func passwordTextFieldEditingChanged(_ sender: UITextField) {
        if saveButton.alpha != 1.0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.saveButton.alpha = 1.0
            })
        }
        
        if let text = sender.text {
            if text.characters.count > 5 {
                passwordLabel.textColor = .waveGreen
            } else {
                passwordLabel.textColor = .waveRed
            }
            
            if text == confirmPasswordTextField.text {
                confirmPasswordLabel.textColor = .waveGreen
            } else {
                confirmPasswordLabel.textColor = .waveRed
            }
        } else {
            passwordLabel.textColor = .waveRed
        }
    }
    
    @IBAction func confirmPasswordTextFieldEditingChanged(_ sender: UITextField) {
        if let text = sender.text {
            if text == passwordTextField.text {
                confirmPasswordLabel.textColor = .waveGreen
            } else {
                confirmPasswordLabel.textColor = .waveRed
            }
        } else {
            confirmPasswordLabel.textColor = .waveRed
        }
    }

    @IBAction func giveFeedbackPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "feedbackViewController") as? FeedbackModalViewController {
            vc.modalPresentationStyle = .overCurrentContext

            present(vc, animated: false, completion: nil)
        }
    }
    
    @IBAction func clearPushIDsPressed(_ sender: UIButton) {
        let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("pushNotificationIds")
        ref.observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Bool] {
                if value.count > 1 {
                    let alert = UIAlertController(title: "⚠️ Warning ⚠️",
                                                  message: "There was more than 1 notification ID that was found on your profile. Do you wish to delete the ones that are not this current device? This will generally fix multiple notifications from appearing.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                        if let id = OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId {
                            for (key, _) in value {
                                if key != id  {
                                    ref.child(key).removeValue()
                                }
                            }
                            sender.setTitle("Cleared!", for: .normal)
                        }
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    sender.setTitle("Cleared!", for: .normal)
                }
            }
        }
    }

    @IBAction func wantsToLogout(_ sender: UIButton) {
        let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        ref.child("isOnline").removeValue()

        SentryManager.shared.clearUserCredentials()
        
        if let id = OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId {
            ref.child("pushNotificationIds").child(id).removeValue()
        }
        
        do {
            try Auth.auth().signOut()
            
            KeychainWrapper.standard.removeObject(forKey: UserInfoKeys.UserPass)
            
            FBSDKLoginManager().logOut()
            
            KeychainWrapper.standard.removeObject(forKey: TwitterInfoKeys.token)
            KeychainWrapper.standard.removeObject(forKey: TwitterInfoKeys.secret)
            
            self.dismissParent()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: logoutNotificationKey), object: nil, userInfo: nil)
        } catch {
            Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("isOnline").setValue(true)
            print("Error signing out")
            SentryManager.shared.sendEvent(withError: error)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        if passwordLabel.textColor == .waveGreen && confirmPasswordLabel.textColor == .waveGreen {
            Auth.auth().currentUser!.updatePassword(to: passwordTextField.text!, completion: { error in
                if let error = error {
                    print("Error saving password: \(error.localizedDescription)")
                    SentryManager.shared.sendEvent(withError: error)
                } else {
                    KeychainWrapper.standard.set(self.passwordTextField.text!, forKey: UserInfoKeys.UserPass)
                }
            })
        }
        
        if fullName != fullNameTextField.text && fullNameLabel.textColor == .waveGreen {
            let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
            let updates = ["fullName": fullNameTextField.text!]
            ref.updateChildValues(updates) { error, ref in
                if let error = error {
                    print("Error saving name: \(error.localizedDescription)")
                    SentryManager.shared.sendEvent(withError: error)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: nameChangeNotificationKey), object: nil, userInfo: nil)
                }
            }
        }
        
        dismissParent()
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        dismissParent()
    }
    
    // MARK: - Helpers
    
    private func dismissParent() {
        if let parent = parent as? SettingsViewController {
            parent.prepareForDismissal {
                parent.dismiss(animated: false, completion: nil)
            }
        }
    }

}
