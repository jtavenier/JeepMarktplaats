//
//  CreateReviewContainerViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 1/11/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper
import CoreLocation

class CreateReviewContainerViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var topBackgroundView: UIView!

    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var farLeftStar: UIImageView!
    @IBOutlet weak var leftMidStar: UIImageView!
    @IBOutlet weak var midStar: UIImageView!
    @IBOutlet weak var rightMidStar: UIImageView!
    @IBOutlet weak var farRightStar: UIImageView!
    
    @IBOutlet weak var fakePlaceholderLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    private var reviewedBeforeKey: String?
    private var previousReviewAmountOfStars = 0
    
    private var amountOfStars = 0 {
        didSet {
            switch amountOfStars {
            case 1:
                farLeftStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                
                leftMidStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                midStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                rightMidStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                farRightStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
            case 2:
                farLeftStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                leftMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                
                midStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                rightMidStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                farRightStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
            case 3:
                farLeftStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                leftMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                midStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                
                rightMidStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
                farRightStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
            case 4:
                farLeftStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                leftMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                midStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                rightMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                
                farRightStar.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
            default:
                farLeftStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                leftMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                midStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                rightMidStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                farRightStar.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
            }
        }
    }
    
    var product: Product!
    var userId: String!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.roundCorners(radius: 8.0)
        view.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(pan)

        topBackgroundView.backgroundColor = .waveRed
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let string = formatter.string(from: floor(product.price) as NSNumber)
        let endIndex = string!.index(string!.endIndex, offsetBy: -3)
        let truncated = String(string![..<endIndex]) // Remove the .00 from the price.
        priceLabel.text = truncated
        
        imageView.roundCorners()
        
        questionLabel.text = ""
        
        formatStar(farLeftStar)
        formatStar(leftMidStar)
        formatStar(midStar)
        formatStar(rightMidStar)
        formatStar(farRightStar)
        
        textView.delegate = self
        
        cancelButton.layer.borderColor = cancelButton.titleLabel!.textColor.cgColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.roundCorners(radius: 8.0)
        
        submitButton.roundCorners(radius: 8.0)
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor.clear
        checkIfPreviouslyReviewed()
        
        grabProfileDetails()
    }
    
    // MARK: - TextView delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.resignFirstResponder()

        if !fakePlaceholderLabel.isHidden {
            fakePlaceholderLabel.isHidden = true
        }

        let vc = KeyboardHelperViewController.getVc(with: textView.text) { string in
            if string == "" {
                self.textView.text = ""
                self.fakePlaceholderLabel.isHidden = false
            } else {
                self.textView.text = string
                self.fakePlaceholderLabel.isHidden = true
            }
        }
        present(vc, animated: false, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func farLeftPressed(_ sender: UIButton) {
        amountOfStars = 1
    }
    
    @IBAction func leftMidPressed(_ sender: UIButton) {
        amountOfStars = 2
    }
    
    @IBAction func midPressed(_ sender: UIButton) {
        amountOfStars = 3
    }
    
    @IBAction func rightMidPressed(_ sender: UIButton) {
        amountOfStars = 4
    }
    
    @IBAction func farRightPressed(_ sender: UIButton) {
        amountOfStars = 5
    }
    
    @objc private func viewTapped() {
        view.endEditing(false)
    }
    
    @IBAction func wantsToCancel(_ sender: UIButton) {
        dismissParent()
    }
    
    @IBAction func wantsToSubmit(_ sender: UIButton) {
        
        var viewsToShake: [UIView] = []
        
        if amountOfStars == 0 {
            viewsToShake.append(farLeftStar)
            viewsToShake.append(leftMidStar)
            viewsToShake.append(midStar)
            viewsToShake.append(rightMidStar)
            viewsToShake.append(farRightStar)
        }
        
        if textView.text == "" {
            viewsToShake.append(fakePlaceholderLabel)
            fakePlaceholderLabel.isHidden = false
        }
        
        if viewsToShake.count == 0 && fakePlaceholderLabel.isHidden {
            if let uid = Auth.auth().currentUser?.uid {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy HH:mm:ss"
                formatter.timeZone = TimeZone(identifier: "America/New_York")
                let now = formatter.string(from: Date())
                
                let review: [String: Any] = ["rating": amountOfStars,
                                             "timeReviewed": now,
                                             "comment": textView.text,
                                             "reviewerId": uid,
                                             "productId": product.uid]
                
                let ref = Database.database().reference().child("reviews").child(userId)
                
                if let key = reviewedBeforeKey {
                    let childUpdates = [key: review]
                    ref.updateChildValues(childUpdates)
                    
                    ref.child("reviewNumbers").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        if var reviewNumbers = currentData.value as? [String: Int] {
                            if let _ = reviewNumbers["sum"] {
                                reviewNumbers["sum"]! += self.amountOfStars - self.previousReviewAmountOfStars
                                
                                switch self.previousReviewAmountOfStars {
                                case 1:
                                    reviewNumbers["oneStars"]! -= 1
                                case 2:
                                    reviewNumbers["twoStars"]! -= 1
                                case 3:
                                    reviewNumbers["threeStars"]! -= 1
                                case 4:
                                    reviewNumbers["fourStars"]! -= 1
                                default:
                                    reviewNumbers["fiveStars"]! -= 1
                                }
                                
                                switch self.amountOfStars {
                                case 1:
                                    reviewNumbers["oneStars"]! += 1
                                case 2:
                                    reviewNumbers["twoStars"]! += 1
                                case 3:
                                    reviewNumbers["threeStars"]! += 1
                                case 4:
                                    reviewNumbers["fourStars"]! += 1
                                default:
                                    reviewNumbers["fiveStars"]! += 1
                                }
                                
                                currentData.value = reviewNumbers
                            }
                        }
                        return TransactionResult.success(withValue: currentData)
                    }) { (error, committed, snapshot) in
                        if let error = error {
                            print("Error while updating reviews: \(error.localizedDescription)")
                            SentryManager.shared.sendEvent(withError: error)
                        }
                    }
                } else {
                    let childUpdates = [ref.childByAutoId().key: review]
                    ref.updateChildValues(childUpdates)
                    
                    PushNotification.sender.pushReview(withRating: amountOfStars, withRecipientId: userId)
                    
                    var starCountString = ""
                    switch amountOfStars {
                    case 1:
                        starCountString = "oneStars"
                    case 2:
                        starCountString = "twoStars"
                    case 3:
                        starCountString = "threeStars"
                    case 4:
                        starCountString = "fourStars"
                    default:
                        starCountString = "fiveStars"
                    }
                    
                    ref.child("reviewNumbers").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        if var reviewNumbers = currentData.value as? [String: Int] {
                            if let count = reviewNumbers["count"] {
                                reviewNumbers["sum"]! += self.amountOfStars
                                reviewNumbers["count"]! = count + 1
                                reviewNumbers[starCountString]! += 1
                                
                                currentData.value = reviewNumbers
                            }
                        } else {
                            var newNumbers = ["count": 1, "sum": self.amountOfStars, "oneStars": 0, "twoStars": 0, "threeStars": 0, "fourStars": 0, "fiveStars": 0]
                            newNumbers[starCountString] = 1
                            currentData.value = newNumbers
                        }
                        return TransactionResult.success(withValue: currentData)
                    }) { (error, committed, snapshot) in
                        if let error = error {
                            print("Error while updating reviews: \(error.localizedDescription)")
                            SentryManager.shared.sendEvent(withError: error)
                        }
                    }
                }
                
                dismissParent()
            }
        } else {
            for view in viewsToShake {
                shakeView(view: view)
            }
        }
        
    }
    
    // MARK: - Helpers
    
    private func formatStar(_ star: UIImageView) {
        star.image = star.image!.withRenderingMode(.alwaysTemplate)
        star.tintColor = #colorLiteral(red: 0.7215686275, green: 0.7607843137, blue: 0.7803921569, alpha: 1)
    }
    
    private func dismissParent() {
        if let parent = parent as? CreateReviewViewController {
            parent.prepareForDismissal {
                parent.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    private func grabProfileDetails() {
        let sellerRef = Database.database().reference().child("users").child(userId)
        sellerRef.observeSingleEvent(of: .value, with: { snapshot in
            if let userDict = snapshot.value as? [String: Any] {
                
                if let fullName = userDict["fullName"] as? String {
                    DispatchQueue.main.async {
                        self.questionLabel.text = "Overall, how would you rate \(fullName) through the process of your purchase?"
                    }
                }
                if let profileUrl = userDict["profileImage"] as? String {
                    self.imageView.sd_setImage(with: URL(string: profileUrl), placeholderImage: #imageLiteral(resourceName: "DefaultProfilePicture"))
                }
            }
        })
    }
    
    private func checkIfPreviouslyReviewed() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("reviews").child(userId).queryOrdered(byChild: "reviewerId").queryStarting(atValue: uid).queryEnding(atValue: uid)
            ref.observeSingleEvent(of: .value, with: { snapshot in
                if let userReviewsDict = snapshot.value as? [String: AnyObject] {
                    
                    for (key, value) in userReviewsDict {
                        if let review = value as? [String: AnyObject] {
                            if review["productId"] as! String == self.product.uid {
                                self.reviewedBeforeKey = key
                                self.previousReviewAmountOfStars = review["rating"] as! Int
                                
                                DispatchQueue.main.async {
                                    self.amountOfStars = review["rating"] as! Int
                                    self.textView.text = review["comment"] as! String
                                    self.fakePlaceholderLabel.isHidden = true
                                    
                                    self.submitButton.isEnabled = true
                                    self.submitButton.backgroundColor = #colorLiteral(red: 0.8470588235, green: 0.337254902, blue: 0.2156862745, alpha: 1)
                                }
                            }
                        }
                    }
                    
                }
                
                DispatchQueue.main.async {
                    self.submitButton.isEnabled = true
                    self.submitButton.backgroundColor = #colorLiteral(red: 0.8470588235, green: 0.337254902, blue: 0.2156862745, alpha: 1)
                }
            })
        }
    }
    
    private func shakeView(view: UIView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.08
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x - 10, y: view.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x + 10, y: view.center.y))
        view.layer.add(animation, forKey: "position")
    }
    
}
