//
//  SettingsTableViewController.swift
//  Kontax Cam
//
//  Created by Kevin Laminto on 12/6/20.
//  Copyright © 2020 Kevin Laminto. All rights reserved.
//

import UIKit
import SwiftUI
import SafariServices
import MessageUI
import Backend

class SettingsTableViewController: UITableViewController {
    
    private var viewModel: SettingsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationBarTitle("Settings".localized, backgroundColor: .systemGroupedBackground)
        self.addCloseButton()
        viewModel = SettingsViewModel(delegate: self)
        tableView.delegate = viewModel
        tableView.dataSource = viewModel
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupView() {
        let settingsFooterView = UIHostingController(rootView: SettingsFooterView())
        settingsFooterView.view.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 100)
        settingsFooterView.view.backgroundColor = .clear
        self.tableView.tableFooterView = settingsFooterView.view
    }
}

extension SettingsTableViewController: SettingsViewModelDelegate {
    func changelogTapped() {
        if let url = URL(string: "https://kontax.cam/change-log") {
            let sfSafariVC = SFSafariViewController(url: url)
            present(sfSafariVC, animated: true)
        }
    }
    
    func restorePurchaseTapped() {
        let window = UIApplication.shared.keyWindow!
        let loadingVC = LoadingViewController()
        loadingVC.shouldHideTitleLabel = true
        
        window.addSubview(loadingVC.view)
        
        IAPManager.shared.restorePurchases { (isSuccessful) in
            if isSuccessful == nil {
                AlertHelper.shared.presentOKAction(
                    withTitle: "Nothing to restore",
                    to: self
                )
            } else if isSuccessful! {
                AlertHelper.shared.presentOKAction(
                    withTitle: "Puchase restore was succesful",
                    to: self
                )
            } else {
                AlertHelper.shared.presentOKAction(
                    withTitle: "An error has occured",
                    andMessage: "There was a problem restoring the purchase. Please try again later.",
                    to: self
                )
            }
            
            loadingVC.view.removeFromSuperview()
        }
    }
    
    func surveyFormTapped() {
        if let url = URL(string: "https://kontaxcam.typeform.com/to/RDApdKEH") {
            let sfSafariVC = SFSafariViewController(url: url)
            present(sfSafariVC, animated: true)
        }
    }
    
    func appearanceTapped() {
        let appearanceVC = AppearanceTableViewController(style: .insetGrouped)
        self.show(appearanceVC, sender: self)
    }
    
    func apppIconsTapped() {
        let appIconsVC = AppIconsTableViewController(style: .insetGrouped)
        self.show(appIconsVC, sender: self)
    }
    
    func instagramTapped() {
        if let url = URL(string: "https://instagram.com/kontaxcam") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let sfSafariVC = SFSafariViewController(url: url)
                present(sfSafariVC, animated: true)
            }
        }
    }
    
    func twitterTapped() {
        if let url = URL(string: "https://twitter.com/kontaxcam") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let sfSafariVC = SFSafariViewController(url: url)
                present(sfSafariVC, animated: true)
            }
        }
    }
    
    func websiteTapped() {
        if let url = URL(string: "https://kontax.cam") {
            let sfSafariVC = SFSafariViewController(url: url)
            present(sfSafariVC, animated: true)
        }
        
    }
    
    func emailTapped() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["kevinlaminto.dev@gmail.com"])
            mail.setSubject("[Kontax-Cam] Hi there! ✉️")
            
            present(mail, animated: true)
        } else {
            AlertHelper.shared.presentOKAction(withTitle: "No mail account.", andMessage: "Please configure a mail account in order to send email. Or, manually email it to kevinlaminto.dev@gmail.com", to: self)
        }
    }
    
    func privacyTapped() {
        if let url = URL(string: "https://kontax.cam/privacy-policy") {
            let sfSafariVC = SFSafariViewController(url: url)
            present(sfSafariVC, animated: true)
        }
    }
    
    func deleteAllTapped() {
        let alert = UIAlertController(title: "Delete all lab images?", message: "This will free up some space in your device.", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            guard let sharedGroupPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kevinlaminto.kontaxcam") else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: sharedGroupPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                for fileURL in fileURLs { try FileManager.default.removeItem(at: fileURL) }
                
                AlertHelper.shared.presentOKAction(withTitle: "Lab images has been successfully deleted.", to: self)
            } catch { print(error) }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
