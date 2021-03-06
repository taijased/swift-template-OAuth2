//
//  MainViewController.swift
//  OAuth2
//
//  Created by Maxim Spiridonov on 07/04/2019.
//  Copyright © 2019 Maxim Spiridonov. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn


class MainViewController: UIViewController {
    
    private var provider: String?
    private var currentUser: UserProfile?
    
    @IBOutlet weak var userProvider: UILabel! {
        didSet {
            self.userProvider.isHidden = true
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userEmail: UILabel! {
        didSet {
            userEmail.text = ""
        }
    }
    @IBOutlet weak var userName: UILabel! {
        didSet {
            userName.text = ""
        }
    }
    @IBOutlet weak var userPicture: UIImageView!
    
  
    
    lazy var logoutButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 32,
                                   y: view.frame.height - 128,
                                   width: view.frame.width - 64,
                                   height: 50)
        button.backgroundColor = UIColor(hexValue: "#86CA9F", alpha: 1)
        button.setTitle("Log Out", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(signOut), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        checkLoggedIn()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserData()
    }
    
    private func setupViews() {
        view.addSubview(logoutButton)
    }
}

// MARK: Facebook SDK
extension MainViewController {
    
    private func checkLoggedIn() {
        
        if Auth.auth().currentUser == nil {
            
            DispatchQueue.main.async {
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let loginViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                self.present(loginViewController, animated: true)
                return
            }
        }
    }
}

extension MainViewController {
    
    
    private func openLoginViewController() {
        
        // проверяем пользователя в Firebase
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let loginViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                self.present(loginViewController, animated: true)
                return
            }
        } catch let error {
            print("Failed to sign out with error:" + error.localizedDescription)
        }
        
    }
    
    private func fetchUserData() {
        if Auth.auth().currentUser != nil {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            Database.database().reference()
            .child("users")
            .child(uid)
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let userData = snapshot.value as? [String: Any] else { return }
                    self.currentUser = UserProfile(data: userData, true)
                    print(userData)
                    self.setupUserUI()
                }) { (error) in
                    print(error)
            }
        }
    }
    
    private func setupUserUI() {
        
        guard let user = currentUser else { return }
        let url = URL(string: user.picture!)
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.userPicture.image = UIImage(data: data!)
                self.userName.text = user.name!
                self.userEmail.text = user.email!
                self.userProvider.text = self.getProviderData()
                self.userProvider.isHidden = false

            }
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    @objc private func signOut() {
        if let providerData = Auth.auth().currentUser?.providerData {
            for userInfo in providerData {
                switch userInfo.providerID {
                case "facebook.com":
                    FBSDKLoginManager().logOut()
                    print("User did log out Facebook")
                    openLoginViewController()
                case "google.com":
                    GIDSignIn.sharedInstance()?.signOut()
                    FBSDKLoginManager().logOut()
                    print("User did log out Google")
                    openLoginViewController()
                default:
                    print("User is signed in with \(userInfo.providerID)")
                }
            }
        }
    }
    private func  getProviderData() -> String {
        var greetings = ""
        
        if let providerData = Auth.auth().currentUser?.providerData {
            for userInfo in providerData {
                switch userInfo.providerID {
                case "facebook.com":
                    provider = "Facebook"
                case "google.com":
                    provider = "Google"
                default:
                    break
                }
            }
            greetings = "Logged in with \(provider!)"
        }
        
        return greetings
    }

}

