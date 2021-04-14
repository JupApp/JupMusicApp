//
//  QueueTabBarController.swift
//  Jup
//
//  Created by Nick Venanzi on 4/13/21.
//

import Foundation

class QueueTabBarController: UITabBarController, UITabBarControllerDelegate {
    var currentlySelectedVC: UIViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard item.badgeValue == "Search" else {
            return
        }
        
        
    }
    
//    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        print("AHHHHHH")
//        guard let source = tabBarController. as? QueueVC,
//              let destination = viewController as? SearchVC else {
//            return
//        }
//        print("poop")
//    }
}
