//
//  CreateReviewViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 1/11/17.
//  Copyright © 2017 XYello, Inc. All rights reserved.
//

import UIKit

class CreateReviewViewController: UIViewController {

    @IBOutlet weak var container: UIView!
    
    private var animator: UIDynamicAnimator!
    
    var product: Product!
    var userId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator = UIDynamicAnimator()
        
        container.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if container.alpha != 1.0 {
            let point = CGPoint(x: container.frame.midX, y: container.frame.midY)
            let snap = UISnapBehavior(item: container, snapTo: point)
            snap.damping = 1.0
            
            container.frame = CGRect(x: container.frame.origin.x + view.frame.width, y: -container.frame.origin.y - view.frame.height, width: container.frame.width, height: container.frame.height)
            container.alpha = 1.0
            
            animator.addBehavior(snap)
            
            UIView.animate(withDuration: 0.25, animations: {
                self.view.backgroundColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 0.7527527265)
            })
        }
    }
    
    // MARK: - Dismissal
    
    func prepareForDismissal(dismissCompletion: @escaping () -> Void) {
        animator.removeAllBehaviors()
        
        let gravity = UIGravityBehavior(items: [container])
        gravity.gravityDirection = CGVector(dx: 0.0, dy: 9.8)
        animator.addBehavior(gravity)
        
        let item = UIDynamicItemBehavior(items: [container])
        item.addAngularVelocity(-CGFloat.pi / 2, for: container)
        animator.addBehavior(item)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.container.alpha = 0.0
            self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        }, completion: { done in
            dismissCompletion()
        })
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destination = segue.destination as? CreateReviewContainerViewController {
            destination.product = product
            destination.userId = userId
        }
    }

}
