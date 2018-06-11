//
//  KeyboardHelperViewController.swift
//  The Wave
//
//  Created by Andrew Robinson on 7/22/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit

class KeyboardHelperViewController: UIViewController, UITextViewDelegate {

    static func getVc(with text: String, withNewTextHandler handler: @escaping ((String) -> ())) -> KeyboardHelperViewController {
        let vc = KeyboardHelperViewController(text: text)
        vc.modalPresentationStyle = .overCurrentContext
        vc.textHandler = handler

        return vc
    }

    static func getVc(with text: String, with characterLimit: UInt, withNewTextHandler handler: @escaping ((String) -> ())) -> KeyboardHelperViewController {
        let vc = KeyboardHelperViewController(text: text, characterLimit: characterLimit)
        vc.modalPresentationStyle = .overCurrentContext
        vc.textHandler = handler

        return vc
    }

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var characterCounterLabel: UILabel!
    @IBOutlet weak var textView: UITextView!

    @IBOutlet weak var containerToBottomConstraint: NSLayoutConstraint!
    
    private var text: String!
    private var characterLimit: UInt?

    fileprivate var textHandler: ((String) -> ())!

    // MARK: - Init

    private init(text: String) {
        self.text = text

        super.init(nibName: nil, bundle: nil)
    }

    private init(text: String, characterLimit: UInt) {
        self.text = text
        self.characterLimit = characterLimit

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = text

        container.clipsToBounds = true
        container.roundCorners(radius: 8.0)

        textView.delegate = self

        if let limit = characterLimit {
            characterCounterLabel.isHidden = false
            characterCounterLabel.text = "\(text.characters.count)/\(limit)"
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(prepareForDismissal))
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        containerToBottomConstraint.constant = -20 - container.frame.height
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.becomeFirstResponder()
    }

    // MARK: - TextView delegate

    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
        if let limit = characterLimit {
            characterCounterLabel.text = "\(text.characters.count)/\(limit)"
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var shouldAllowCharacter = true

        if let old = textView.text, let limit = characterLimit {
            if UInt(old.characters.count + text.characters.count) > limit {
                shouldAllowCharacter = false
            }
        }

        return shouldAllowCharacter
    }

    // MARK: - Actions

    @objc private func keyboardWillShow(notification: Notification) {
        let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
        containerToBottomConstraint.constant = 20 + frame.height

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 0.7527527265)
        }
    }

    @IBAction func doneButton(_ sender: UIButton) {
        prepareForDismissal()
    }

    // MARK: - Helpers

    @objc private func prepareForDismissal() {
        textHandler(text)

        textView.resignFirstResponder()

        containerToBottomConstraint.constant = -20 - container.frame.height

        UIView.animate(withDuration: 0.25, animations: {
            self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            self.view.layoutIfNeeded()
        }, completion: { done in
            self.dismiss(animated: true, completion: nil)
        })
    }

}
