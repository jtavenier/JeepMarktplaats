//
//  ProductViewerContainerViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 1/9/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit
import Firebase
import Lightbox

class ProductViewerContainerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private enum CellType {
        case text
        case details
        case seller
        case exCheck
    }

    @IBOutlet weak var markAsSoldButton: UIButton!

    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var viewsCountLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    private var likesRef: DatabaseReference!
    private var viewsRef: DatabaseReference!
    
    private var tableFormat: [[String: CellType]] = []
    private var textCellLayout: [String] = []
    private var checkCellLayout: [Bool] = []
    
    private var seller: User!
    
    var favoriteCount = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let number = formatter.string(from: NSNumber(value: favoriteCount))
            likeCountLabel.text = "\(number!)"
        }
    }
    var viewsCount = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let number = formatter.string(from: NSNumber(value: viewsCount))
            viewsCountLabel.text = "\(number!)"
        }
    }
    
    var product: Product!
    var chatOpen: Bool = false
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.roundCorners(radius: 8.0)
        view.clipsToBounds = true

        markAsSoldButton.roundCorners(radius: 8.0)
        
        priceContainer.layer.shadowRadius = 3.0
        priceContainer.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        priceContainer.roundCorners(radius: 8.0)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        orangeButton.roundCorners(radius: 8.0)
        greenButton.roundCorners(radius: 8.0)
        
        closeButton.layer.borderColor = closeButton.titleLabel!.textColor.cgColor
        closeButton.layer.borderWidth = 1.0
        closeButton.roundCorners(radius: 8.0)
        
        if let image = likeImageView.image {
            likeImageView.image = image.withRenderingMode(.alwaysTemplate)
            likeImageView.tintColor = #colorLiteral(red: 0.2235294118, green: 0.2235294118, blue: 0.2235294118, alpha: 0.2034658138)
        }
        
        tableFormat = [["Item Name": .text],
                       ["Make & Model": .text],
                       ["Price": .text],
                       ["Condition": .text],
                       ["Location": .text],
                       ["Details": .details],
                       ["Seller": .seller],
                       ["Willing to Ship Item": .exCheck],
                       ["Accepts PayPal": .exCheck],
                       ["Accepts Cash": .exCheck]]
        
        if let uid = Auth.auth().currentUser?.uid {
            if uid == product.ownerId {
                orangeButton.setTitle("Delete", for: .normal)
                greenButton.isHidden = true
            } else if product.isSold {
                markAsSoldButton.isHidden = true
                orangeButton.isHidden = true
                greenButton.isHidden = true
            } else {
                markAsSoldButton.isHidden = true
                orangeButton.setTitle("Make Offer", for: .normal)
                greenButton.setTitle("Message", for: .normal)
            }
        } else {
            markAsSoldButton.isHidden = true
            orangeButton.isHidden = true
            greenButton.isHidden = true
        }
        if chatOpen {
            orangeButton.isHidden = true
            greenButton.isHidden = true
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let string = formatter.string(from: floor(product.price) as NSNumber)
        let endIndex = string!.index(string!.endIndex, offsetBy: -3)
        let truncated = String(string![..<endIndex]) // Remove the .00 from the price.
        priceLabel.text = truncated
        
        textCellLayout = [product.name, product.jeepModel.name, truncated, product.condition.description, product.cityStateString ?? "None provided"]
        checkCellLayout = [product.willingToShip, product.acceptsPayPal, product.acceptsCash]
        
        grabProductImages()
        grabSellerInfo()
        checkForCurrentUserLike()
        setupLikesAndViewsListeners()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        likesRef.removeAllObservers()
        viewsRef.removeAllObservers()
    }
    
    // MARK: - CollectionView datasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return product.imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ProductViewerImageCollectionViewCell
        
        let url = URL(string: product.imageUrls[indexPath.row])
        cell.imageView.sd_setImage(with: url)
        
        return cell
    }

    // MARK: - CollectionView delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var images = [LightboxImage]()
        for url in product.imageUrls {
            images.append(LightboxImage(imageURL: URL(string: url)!))
        }

        let box = LightboxController(images: images, startIndex: indexPath.row)
        LightboxConfig.PageIndicator.enabled = false
        present(box, animated: true, completion: nil)
    }
    
    // MARK: - TableView datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableFormat.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        let dictionary = tableFormat[indexPath.row]
        let descriptionName = Array(dictionary.keys)[0]
        let type = Array(dictionary.values)[0]
        let imageName = evaluateImageName(withDescription: descriptionName)
        
        if type == .text {
            let textCell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ProductViewerTextTableViewCell
            
            textCell.sideImageView.image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            textCell.sideImageView.tintColor = #colorLiteral(red: 0.9098039216, green: 0.9058823529, blue: 0.8235294118, alpha: 1)
            textCell.detailNameLabel.text = descriptionName
            
            let detailText = textCellLayout[indexPath.row]
            textCell.textDetailLabel.text = detailText
            
            cell = textCell
        } else if type == .details {
            let detailsCell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! ProductViewerDetailsTableViewCell
            
            detailsCell.sideImageView.image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            detailsCell.sideImageView.tintColor = #colorLiteral(red: 0.9098039216, green: 0.9058823529, blue: 0.8235294118, alpha: 1)
            detailsCell.detailNameLabel.text = descriptionName
            detailsCell.hasOriginalBox = product.originalBox
            detailsCell.datePostedLabel.text = product.relativeDate
            
            if let releaseYear = product.releaseYear {
                detailsCell.releaseYearLabel.text = "\(releaseYear)"
            } else {
                detailsCell.releaseYearLabel.text = ""
            }
            
            if let itemDescription = product.detailedDescription {
                detailsCell.descriptionTextView.text = "\(itemDescription)"
            } else {
                detailsCell.descriptionTextView.text = "No description provided."
            }
            
            cell = detailsCell
        } else if type == .seller {
            let sellerCell = tableView.dequeueReusableCell(withIdentifier: "sellerCell", for: indexPath) as! ProductViewerSellerTableViewCell
            
            sellerCell.sideImageView.image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            sellerCell.sideImageView.tintColor = #colorLiteral(red: 0.9098039216, green: 0.9058823529, blue: 0.8235294118, alpha: 1)
            sellerCell.detailNameLabel.text = descriptionName
            sellerCell.sellerNameLabel.text = seller.fullName
            
            var reviewsCountString = "\(seller.totalNumberOfReviews) reviews"
            if seller.totalNumberOfReviews == 1 {
                reviewsCountString = "\(seller.totalNumberOfReviews) review"
            }
            sellerCell.numberOfReviewsLabel.text = reviewsCountString
            
            sellerCell.amountOfStars = seller.starRating
            
            sellerCell.sellerImageView.sd_setImage(with: seller.profileUrl, placeholderImage: #imageLiteral(resourceName: "DefaultProfilePicture"))
            
            if seller.twitterVerified {
                sellerCell.twitterVerifiedWithImage.tintColor = #colorLiteral(red: 0.4623369575, green: 0.6616973877, blue: 0.9191944003, alpha: 1)
            }
            if seller.facebookVerified {
                sellerCell.facebookVerifiedWithImage.tintColor = #colorLiteral(red: 0.2784313725, green: 0.3490196078, blue: 0.5764705882, alpha: 1)
            }
            
            cell = sellerCell
        } else if type == .exCheck {
            let exCheckCell = tableView.dequeueReusableCell(withIdentifier: "exCheckCell", for: indexPath) as! ProductViewerExCheckTableViewCell
            
            exCheckCell.sideImageView.image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            exCheckCell.sideImageView.tintColor = #colorLiteral(red: 0.9098039216, green: 0.9058823529, blue: 0.8235294118, alpha: 1)
            exCheckCell.detailNameLabel.text = descriptionName
            
            let index = tableFormat.count - indexPath.row
            exCheckCell.isChecked = checkCellLayout[checkCellLayout.count - index]
            
            cell = exCheckCell
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dictionary = tableFormat[indexPath.row]
        let type = Array(dictionary.values)[0]
        
        var height: CGFloat = 35.0
        
        if type == .details {
            height = 237.0
        } else if type == .seller {
            height = 146.0
        }
        
        return height
    }
    
    // MARK: - TableView delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 6 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "profileModalViewController") as? ProfileModalViewController {
                vc.modalPresentationStyle = .overCurrentContext
                vc.idToPass = product.ownerId
                
                PresentationCenter.manager.present(viewController: vc, sender: self)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func markAsSoldPressed(_ sender: UIButton) {
        let productRef = Database.database().reference()
        let childUpdates: [String: Any] = ["products/\(product.uid!)/isSold": true,
                                           "products/\(product.uid!)/soldModel": "SOLD" + product.jeepModel.name]

        productRef.updateChildValues(childUpdates)

        dismiss(animated: true, completion: nil)
    }

    @IBAction func likeButtonTapped(_ sender: UIButton) {
        if likeImageView.tintColor == #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1) {
            likeImageView.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3)
        } else {
            likeImageView.tintColor = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
        }
        
        let productRef = Database.database().reference().child("products").child(product.uid)
        incrementLikes(forRef: productRef)

    }
    
    @IBAction func orangeButtonTapped(_ sender: UIButton) {
        if sender.currentTitle == "Delete" {
            let alert = UIAlertController(title: "Delete \(product.name!)?", message: "Are you sure you want to delete \(product.name!)?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
                self.deleteProduct()
            }))
            
            present(alert, animated: true, completion: nil)
        } else if sender.currentTitle == "Make Offer" {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: openChatControllerNotificationKey), object: nil, userInfo:
                [Conversation.conversationIDKey: "",
                 Conversation.productIDKey: product.uid,
                 Conversation.productOwnerIDKey: product.ownerId,
                 Conversation.otherPersonNameKey: seller.fullName,
                 Conversation.preformattedMessageKey: "I would like to buy your item that you have for sale!"])
            dismissParent()
        }
    }
    
    @IBAction func greenButtonTapped(_ sender: UIButton) {
        if sender.currentTitle == "Message" {
            if !chatOpen {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: openChatControllerNotificationKey), object: nil, userInfo:
                    [Conversation.conversationIDKey: "",
                     Conversation.productIDKey: product.uid,
                     Conversation.productOwnerIDKey: product.ownerId,
                     Conversation.otherPersonNameKey: seller.fullName])
            }
            dismissParent()
        }
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismissParent()
    }
    
    // MARK: - Helpers
    
    private func dismissParent() {
        if let parent = parent as? ProductViewerViewController {
            parent.prepareForDismissal {
                parent.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    private func evaluateImageName(withDescription description: String) -> String {
        var imageName = ""
        
        switch description {
        case "Make & Model":
            imageName = "PIPMakeModel"
        case "Price":
            imageName = "PIPPrice"
        case "Condition":
            imageName = "PIPCondition"
        case "Location":
            imageName = "PIPLocation"
        case "Details":
            imageName = "PIPDetails"
        case "Seller":
            imageName = "PVSeller"
        case "Willing to Ship Item":
            imageName = "PIPShip"
        case "Accepts PayPal":
            imageName = "PIPPayPal"
        case "Accepts Cash":
            imageName = "PIPCash"
        default:
            imageName = "PIPItemName"
        }
        
        return imageName
    }
    
    // MARK: - Firebase Database
    
    private func grabProductImages() {
        if product.imageUrls.count < 1 {
            let imagesRef = Database.database().reference().child("products").child(product.uid).child("images")
            imagesRef.observeSingleEvent(of: .value, with: { snapshot in
                for image in snapshot.children.allObjects as! [DataSnapshot] {
                    self.product.imageUrls.append(image.value as! String)
                }
                self.collectionView.reloadData()
            })
        }
    }
    
    private func setupLikesAndViewsListeners() {
        likesRef = Database.database().reference().child("products").child(product.uid).child("likeCount")
        likesRef.observe(.value, with: { snapshot in
            if let count = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.likeCountLabel.text = "\(count)"
                }
            }
        })
        
        viewsRef = Database.database().reference().child("products").child(product.uid).child("viewCount")
        viewsRef.observe(.value, with: { snapshot in
            if let count = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.viewsCountLabel.text = "\(count)"
                }
            }
        })
        
        // Increment views
        let productRef = Database.database().reference().child("products").child(product.uid)
        incrementViews(forRef: productRef.child("viewCount"))
    }
    
    private func grabSellerInfo() {
        seller = User()
        let sellerRef = Database.database().reference().child("users").child(product.ownerId)
        sellerRef.observeSingleEvent(of: .value, with: { snapshot in
            if let userDict = snapshot.value as? [String: Any] {
                
                if let fullName = userDict["fullName"] as? String {
                    self.seller.fullName = fullName
                }
                if let profileUrl = userDict["profileImage"] as? String {
                    self.seller.profileUrl = URL(string: profileUrl)
                }
                
                if let verifiedWith = userDict["verifiedWith"] as? [String: Bool] {
                    self.seller.twitterVerified = verifiedWith["Twitter"] ?? false
                    self.seller.facebookVerified = verifiedWith["Facebook"] ?? false
                }
                
                let ref = Database.database().reference().child("reviews").child(self.product.ownerId).child("reviewNumbers")
                ref.observeSingleEvent(of: .value, with: { snapshot in
                    if let numbers = snapshot.value as? [String: Int] {
                        let count = numbers["count"]!
                        let number = Double(numbers["sum"]!) / Double(count)
                        let roundedNumber = number.roundTo(places: 1)
                        
                        self.seller.starRating = self.determineStarsfor(number: roundedNumber)
                        
                        DispatchQueue.main.async {
                            self.seller.totalNumberOfReviews = count
                        }
                    }
                    
                    let indexPath = IndexPath(row: 5, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                })
            }
        })
    }
    
    private func determineStarsfor(number: Double) -> Int {
        let wholeNumber = Int(number)
        var starsToTurnOn = wholeNumber
        
        if number - Double(wholeNumber) >= 0.9 {
            starsToTurnOn += 1
        }
        
        return starsToTurnOn
    }
    
    private func incrementLikes(forRef ref: DatabaseReference) {
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var product = currentData.value as? [String : AnyObject], let uid = Auth.auth().currentUser?.uid {
                var likes: Dictionary<String, Bool> = product["likes"] as? [String : Bool] ?? [:]
                var likeCount = product["likeCount"] as? Int ?? 0
                
                let userLikesRef = Database.database().reference().child("user-likes").child(uid)
                
                if let _ = likes[uid] {
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                    userLikesRef.child(self.product.uid).removeValue()
                } else {
                    likeCount += 1
                    likes[uid] = true
                    
                    PushNotification.sender.pushLiked(withProductName: product["name"] as! String, withProductID: self.product.uid, withRecipientId: product["owner"] as! String)
                    
                    let userLikesUpdate = [self.product.uid: true]
                    userLikesRef.updateChildValues(userLikesUpdate)
                }
                product["likeCount"] = likeCount as AnyObject?
                product["likes"] = likes as AnyObject?
                
                DispatchQueue.main.sync {
                    self.likeCountLabel.text = "\(likeCount)"
                }
                
                currentData.value = product
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                SentryManager.shared.sendEvent(withError: error)
            }
        }
        
    }
    
    private func incrementViews(forRef ref: DatabaseReference) {
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if let count = currentData.value as? Int {
                currentData.value = count + 1
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                SentryManager.shared.sendEvent(withError: error)
            }
        }
    }
    
    private func checkForCurrentUserLike() {
        if let uid = Auth.auth().currentUser?.uid {
            var color = #colorLiteral(red: 0.2235294118, green: 0.2235294118, blue: 0.2235294118, alpha: 0.2034658138)
            let likesRef = Database.database().reference().child("products").child(product.uid)
            likesRef.observeSingleEvent(of: .value, with: { snapshot in
                if let product = snapshot.value as? [String: AnyObject] {
                    if let likes = product["likes"] as? [String: Bool] {
                        if let _ = likes[uid] {
                            color = #colorLiteral(red: 0.9529411765, green: 0.6274509804, blue: 0.09803921569, alpha: 1)
                        }
                    }
                    
                }

                DispatchQueue.main.async {
                    self.likeImageView.tintColor = color
                }
                
            })
        }
    }

    private func deleteProduct() {
        let basicRef = Database.database().reference()

        // Grab the chat to delete the user-chats.
        var ref = basicRef.child("chats").queryOrdered(byChild: "productID").queryStarting(atValue: product.uid).queryEnding(atValue: product.uid)
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let chats = snapshot.value as? [String: AnyObject] {
                for (key, _) in chats {

                    // Delete all user-chats associated with this chat.
                    let chatContent = chats[key] as! [String: AnyObject]
                    let participants = chatContent["participants"] as! [String: AnyObject]

                    for (userId, _) in participants {
                        basicRef.child("user-chats").child(userId).child(key).removeValue()
                    }

                    // Then delete the chat.
                    basicRef.child("chats").child(key).removeValue()
                }
            }
        })

        // Grab the products likers to delete from their likes.
        ref = basicRef.child("products").child(product.uid)
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if let productDict = snapshot.value as? [String: AnyObject] {
                if let likers = productDict["likes"] as? [String: Bool] {

                    for (userId, _) in likers {
                        basicRef.child("user-likes").child(userId).child(self.product.uid).removeValue()
                    }

                }
            }

            // Finally, delete the product.
            basicRef.child("products").child(self.product.uid).removeValue()
        })

        // Delete the associated product images. (Attempt to delete all. May error, but best we can do)
        let storage = Storage.storage().reference().child("products").child(product.uid)
        storage.child("1").delete(completion: nil)
        storage.child("2").delete(completion: nil)
        storage.child("3").delete(completion: nil)
        storage.child("4").delete(completion: nil)

        // Delete the location information if it exists.
        product.deleteLocation()

        dismissParent()
    }

}
