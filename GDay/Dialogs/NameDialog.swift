//
//  NameDialog.swift
//  GDay
//
//  Created by Erik Mai on 26/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import UIKit

protocol NameDialogDelegate: class {
    func nameDialog(didCancel dialog: NameDialog)
    func nameDialog(_ dialog: NameDialog, didEnrol: Enrolment)
}

class NameDialog: UIViewController {

    var enrol: Enrolment!
    
    weak var delegate: NameDialogDelegate?
    
    @IBOutlet weak var enrolButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var closeView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeView.layer.cornerRadius = 20
        closeView.layer.borderWidth = 1
        closeView.layer.borderColor = UIColor.gray.cgColor
        // Do any additional setup after loading the view.
        
        userImageView.image = enrol.image
        let tap = UITapGestureRecognizer(target: self, action: #selector(NameDialog.didTapOnClose))
        closeView.isUserInteractionEnabled = true
        closeView.addGestureRecognizer(tap)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func doEnrol(enrol: Enrolment, name: String) {
        KairosAPI.sharedInstance.enrol(enrol.image, subjectId: name) { [unowned self] result in
            switch result {
            case .success:
                enrol.submitted(name: name)
                self.doneEnrol(enrol)
            
            case .error(let error):
                print(error)
                enrol.errorSubmitting(message: error)
                self.doneEnrol(enrol)
                
            }
        }
    }
    func doneEnrol(_ enrol: Enrolment) {
        enrolButton.setTitle("Enrol", for: .normal)
        UIApplication.shared.endIgnoringInteractionEvents()
        dismiss(animated: false, completion: {
            self.delegate?.nameDialog(self, didEnrol: enrol)
        })
    }
    
    @IBAction func didTapOnEnrolButton(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty else {
            nameTextField.becomeFirstResponder()
            return
        }
        
        self.view.endEditing(true)
        enrolButton.setTitle("Enrolling...", for: .normal)
        UIApplication.shared.beginIgnoringInteractionEvents()
        doEnrol(enrol: self.enrol, name: name)
        
    }
    
    @objc func didTapOnClose() {
        dismiss(animated: false, completion: {
            self.delegate?.nameDialog(didCancel: self)
        })
    }

}
