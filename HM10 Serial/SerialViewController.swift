//
//  SerialViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore

/// The option to add a \n or \r or \r\n to the end of the send message
enum MessageOption: Int {
    case noLineEnding,
         newline,
         carriageReturn,
         carriageReturnAndNewline
}

/// The option to add a \n to the end of the received message (to make it more readable)
enum ReceivedMessageOption: Int {
    case none,
         newline
}

final class SerialViewController: UIViewController, UITextFieldDelegate, BluetoothSerialDelegate {

//MARK: IBOutlets
    
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! // used to move the textField up when the keyboard is present
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var rectView: UIView!
    
    // Force & Rect Data
    var force: CGFloat = 0.0
    var leftRectPoints: Dictionary<String, CGPoint> = [:]
    var rightRectPoints: Dictionary<String, CGPoint> = [:]
    
    // Force filled shape
    var right_shape_filled: CAShapeLayer!
    var left_shape_filled: CAShapeLayer!


//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        // UI
        mainTextView.text = "Force sensor is not connected. Please Connect!\n"
        
        reloadView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        
        // we want to be notified when the keyboard is shown (so we can move the textField up)
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // to dismiss the keyboard if the user taps outside the textField while editing
        let tap = UITapGestureRecognizer(target: self, action: #selector(SerialViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // style the bottom UIView
        bottomView.layer.masksToBounds = false
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -1)
        bottomView.layer.shadowRadius = 0
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowColor = UIColor.gray.cgColor
        
        // Style the Rect UIView
        rectView.backgroundColor = UIColor.clear
        rectView.frame.size.height = UIScreen.main.bounds.height*0.7
        rectView.frame.size.width = UIScreen.main.bounds.width*0.9
        rectView.sizeToFit()
        
        // Darw Left Rectangle
        let height = self.rectView.frame.height
        let width = self.rectView.frame.width
//        print(height, width)
//        leftRectPoints = drawLeftRect(h: height, w:width)
//        rightRectPoints = drawRightRect(h: height, w:width)
//        print(rightRectPoints)
//        
//        // Test Right Rect fill by force
//        right_shape_filled = fillRightRectByForce(force: 2.0)
//        left_shape_filled = fillLeftRectByForce(force: 3.0)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        // animate the text field to stay above the keyboard
        var info = (notification as NSNotification).userInfo!
        let value = info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = value.cgRectValue
        
        //TODO: Not animating properly
        UIView.animate(withDuration: 1, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
            }, completion: { Bool -> Void in
            self.textViewScrollToBottom()
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // bring the text field back down..
        UIView.animate(withDuration: 1, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.bottomConstraint.constant = 0
        }, completion: nil)

    }
    
    @objc func reloadView() {
        // in case we're the visible view again
        serial.delegate = self
        
        if serial.isReady {
            navItem.title = serial.connectedPeripheral!.name
            barButton.title = "Disconnect"
            barButton.tintColor = UIColor.red
            barButton.isEnabled = true
        } else if serial.centralManager.state == .poweredOn {
            navItem.title = "Bluetooth Serial"
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.isEnabled = true
        } else {
            navItem.title = "Bluetooth Serial"
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.isEnabled = false
        }
    }
    
    func textViewScrollToBottom() {
        let range = NSMakeRange(NSString(string: mainTextView.text).length - 1, 1)
        mainTextView.scrollRangeToVisible(range)
    }
    
    func drawLeftRect(h: CGFloat, w: CGFloat)->Dictionary<String, CGPoint>{
        let cornerRadius = 0.0
        let path = UIBezierPath()
        let p1 = CGPoint(x: w*0.25, y: h*0.80)
        let p2 = CGPoint(x: w*0.40, y: h*0.80)
        let p3 = CGPoint(x: w*0.40, y: h*0.2)
        let p4 = CGPoint(x: w*0.25, y: h*0.2)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.move(to: p4)
        path.addLine(to: p1)
        path.close()
//        print(path.cgPath)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = UIColor.red.cgColor;
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 10
        rectView.layer.addSublayer(shape)
        // Add label
        let Label = UILabel(frame: CGRectMake(w*0.26, h*0.80, 200, 50))
        Label.textColor = UIColor.red
        Label.backgroundColor = UIColor.clear
        Label.font = Label.font.withSize(30)
        Label.text = "Left Hand"
        rectView.addSubview(Label)
        return ["p1": p1, "p2": p2, "p3": p3, "p4": p4]
    }
    
    func drawRightRect(h: CGFloat, w: CGFloat)->Dictionary<String, CGPoint>{
        let cornerRadius = 0.0
        let path = UIBezierPath()
        let p1 = CGPoint(x: w*0.65, y: h*0.80)
        let p2 = CGPoint(x: w*0.80, y: h*0.80)
        let p3 = CGPoint(x: w*0.80, y: h*0.20)
        let p4 = CGPoint(x: w*0.65, y: h*0.20)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.move(to: p4)
        path.addLine(to: p1)
        path.close()
//        print(path.cgPath)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = UIColor.red.cgColor;
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 10
        rectView.layer.addSublayer(shape)
        // Add label
        let Label = UILabel(frame: CGRectMake(w*0.66, h*0.80, 200, 50))
        Label.textColor = UIColor.red
        Label.backgroundColor = UIColor.clear
        Label.font = Label.font.withSize(30)
        Label.text = "Right Hand"
        rectView.addSubview(Label)
        return ["p1": p1, "p2": p2, "p3": p3, "p4": p4]
    }
    

//MARK: BluetoothSerialDelegate
    
//    func serialDidReceiveData(_ data: Data) {
//        print(data)
//    }
    
//    func serialDidReceiveBytes(_ bytes: [UInt8]) {
//        print(bytes)
//    }
    
    func serialDidReceiveString(_ message: String) {
        // add the received text to the textView, optionally with a line break at the end
//        if message.contains("<"){
//            mainTextView.text! += message
//        }
        print(message)
        if message.contains(">"){
            mainTextView.text! += message + "\n\n"
        }
        else {
            mainTextView.text! += message
        }
                
        let message_list = message.components(separatedBy: ",")
//        let fl = message_list[0]
//        let fr = message_list[1]
//        print(message.count)
//        print(message_list)
//        let force_left = CGFloat((fl.components(separatedBy: "=")[1] as NSString).floatValue)
        
//        for m in message_list {
//            mainTextView.text! += m + " ";
//            print(mainTextView.text!)
//        }
                    
        let pref = UserDefaults.standard.integer(forKey: ReceivedMessageOptionKey)
//        left_shape_filled.removeFromSuperlayer()
//        left_shape_filled = fillLeftRectByForce(force: CGFloat(force_left))
        
//        let force_right = CGFloat((fr.components(separatedBy: "=")[1] as NSString).floatValue)
//        print(force_left, force_right)
//        right_shape_filled.removeFromSuperlayer()
//        right_shape_filled = fillRightRectByForce(force: CGFloat(force_right))
        // if pref == ReceivedMessageOption.newline.rawValue { mainTextView.text! += "\n" }
        textViewScrollToBottom()
    }
    
    func fillRightRectByForce(force: CGFloat)->CAShapeLayer{
        let cornerRadius = 0.0
        let path = UIBezierPath()
        print(rightRectPoints)
        let p1 = CGPoint(x: rightRectPoints["p1"]!.x+5, y: rightRectPoints["p1"]!.y-5)
        let p2 = CGPoint(x: rightRectPoints["p2"]!.x-5, y: rightRectPoints["p2"]!.y-5)
        let p3 = CGPoint(x: rightRectPoints["p2"]!.x-5, y: rightRectPoints["p2"]!.y - force*30.0)
        let p4 = CGPoint(x: rightRectPoints["p1"]!.x+5, y: rightRectPoints["p2"]!.y - force*30.0)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        path.addLine(to: p1)
        path.close()
//        print(path.cgPath)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = UIColor.green.cgColor;
        shape.fillColor = UIColor.green.cgColor
        shape.lineWidth = 0
        rectView.layer.addSublayer(shape)
        return shape
    }
    
    func fillLeftRectByForce(force: CGFloat)->CAShapeLayer{
        let cornerRadius = 0.0
        let path = UIBezierPath()
        print(rightRectPoints)
        let p1 = CGPoint(x: leftRectPoints["p1"]!.x+5, y: leftRectPoints["p1"]!.y-5)
        let p2 = CGPoint(x: leftRectPoints["p2"]!.x-5, y: leftRectPoints["p2"]!.y-5)
        let p3 = CGPoint(x: leftRectPoints["p2"]!.x-5, y: leftRectPoints["p2"]!.y - force*30.0)
        let p4 = CGPoint(x: leftRectPoints["p1"]!.x+5, y: leftRectPoints["p2"]!.y - force*30.0)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        path.addLine(to: p1)
        path.close()
//        print(path.cgPath)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = UIColor.blue.cgColor;
        shape.fillColor = UIColor.blue.cgColor
        shape.lineWidth = 0
        rectView.layer.addSublayer(shape)
        return shape
    }
    
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        dismissKeyboard()
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Disconnected"
        hud?.hide(true, afterDelay: 1.0)
    }
    func serialDidConnect(_ peripheral: CBPeripheral) {
        mainTextView.text! = "Sensor Reading\n"
    }
    
    func serialDidChangeState() {
        reloadView()
        if serial.centralManager.state != .poweredOn {
            dismissKeyboard()
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = "Bluetooth turned off"
            hud?.hide(true, afterDelay: 1.0)
        }
    }
    
    
//MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !serial.isReady {
            let alert = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
            messageField.resignFirstResponder()
            return true
        }
        
        // send the message to the bluetooth device
        // but fist, add optionally a line break or carriage return (or both) to the message
        let pref = UserDefaults.standard.integer(forKey: MessageOptionKey)
        var msg = messageField.text!
        switch pref {
        case MessageOption.newline.rawValue:
            msg += "\n"
        case MessageOption.carriageReturn.rawValue:
            msg += "\r"
        case MessageOption.carriageReturnAndNewline.rawValue:
            msg += "\r\n"
        default:
            msg += ""
        }
        
        // send the message and clear the textfield
        serial.sendMessageToDevice(msg)
        messageField.text = ""
        return true
    }
    
    @objc func dismissKeyboard() {
        messageField.resignFirstResponder()
    }
    
    
    
    
//MARK: IBActions

    @IBAction func barButtonPressed(_ sender: AnyObject) {
        if serial.connectedPeripheral == nil {
            performSegue(withIdentifier: "ShowScanner", sender: self)
        } else {
            serial.disconnect()
            reloadView()
        }
    }
}
