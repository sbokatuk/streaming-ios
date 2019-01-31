//
//  DetailViewController.swift
//  R5ProTestbed
//
//  Created by Andy Zupko on 12/16/15.
//  Copyright © 2015 Infrared5. All rights reserved.
//

import UIKit
import R5Streaming

class DetailViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var hostText: UITextField!
    @IBOutlet weak var portText: UITextField!
    @IBOutlet weak var stream1Text: UITextField!
    @IBOutlet weak var stream2Text: UITextField!
    @IBOutlet weak var debugSwitch: UISwitch!
    @IBOutlet weak var videoSwitch: UISwitch!
    @IBOutlet weak var audioSwitch: UISwitch!
    @IBOutlet weak var stream3Text: UITextField!
    
    @IBOutlet weak var licenseText: UILabel!
    @IBOutlet weak var licenseButton: UIButton!
    
    var r5ViewController : BaseTest? = nil
   
    var detailItem: NSDictionary? {
        didSet {
            // Update the view.
           // self.configureView()
        }
    }
    
    @IBAction func onChangeLicense(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Red5 Pro SDK", message: "Enter In Your SDK License", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) in
            let field = alert.textFields?[0]
            let entry = field?.text
            if (entry != "") {
                Testbed.setLicenseKey(value: entry!)
                self.licenseText.text = entry
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler:nil))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Enter SDK License:"
            textField.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        })
        self.present(alert, animated: true, completion:nil);
    }
    
    @IBAction func onStream1NameChange(_ sender: AnyObject) {
        Testbed.setStream1Name(name: stream1Text.text!)
    }
    @IBAction func onStream2NameChange(_ sender: AnyObject) {
        Testbed.setStream2Name(name: stream2Text.text!)
    }
    @IBAction func onStream3NameChange(_ sender: Any) {
        Testbed.setStream3Name(name: stream3Text.text!)
    }
    @IBAction func onStreamNameSwap(_ sender: AnyObject) {
        Testbed.setStream1Name(name: stream2Text.text!)
        Testbed.setStream2Name(name: stream3Text.text!)
        Testbed.setStream3Name(name: stream1Text.text!)
        stream1Text.text = Testbed.parameters!["stream1"] as? String
        stream2Text.text = Testbed.parameters!["stream2"] as? String
        stream3Text.text = Testbed.parameters!["stream3"] as? String
    }
    @IBAction func onHostChange(_ sender: AnyObject) {
        Testbed.setHost(ip: hostText.text!)
    }
    @IBAction func onPortChange(_ sender: Any) {
        Testbed.setServerPort(port: portText.text!)
    }
    @IBAction func onDebugChange(_ sender: AnyObject) {
        Testbed.setDebug(on: debugSwitch.isOn)
    }
    @IBAction func onVideoChange(_ sender: AnyObject) {
        Testbed.setVideo(on: videoSwitch.isOn)
    }
    @IBAction func onAudioChange(_ sender: AnyObject) {
        Testbed.setAudio(on: audioSwitch.isOn)
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        
        hostText.text = Testbed.parameters!["host"] as? String
//        portText.text = Testbed.parameters!["server_port"] as? String
        stream1Text.text = Testbed.parameters!["stream1"] as? String
        stream2Text.text = Testbed.parameters!["stream2"] as? String
        stream3Text.text = Testbed.parameters!["stream3"] as? String
        
        hostText.delegate = self
//        portText.delegate = self
        stream1Text.delegate = self
        stream2Text.delegate = self
        stream3Text.delegate = self
        
        debugSwitch.setOn((Testbed.parameters!["debug_view"] as? Bool)!, animated: false)
        videoSwitch.setOn((Testbed.parameters!["video_on"] as? Bool)!, animated: false)
        audioSwitch.setOn((Testbed.parameters!["audio_on"] as? Bool)!, animated: false)
        
        let licenseKey = Testbed.parameters!["license_key"] as? String
        licenseText.text = licenseKey == nil || licenseKey == "" ? "No License Found" : licenseKey;
        
        if(self.detailItem != nil){
            
            if(self.detailItem!["description"] != nil){

                let navButton = UIBarButtonItem(title: "Info", style: UIBarButtonItemStyle.plain, target: self, action: #selector(DetailViewController.showInfo))
                navButton.imageInsets = UIEdgeInsetsMake(10, 10, 10, 10);

                navigationItem.rightBarButtonItem =    navButton
            }
            
            Testbed.setLocalOverrides(params: self.detailItem!["LocalProperties"] as? NSMutableDictionary)
            
            
            let className = self.detailItem!["class"] as! String
            let mClass = NSClassFromString(className) as! BaseTest.Type;
           
            //only add this view if it isn't HOME
            if(!(mClass is Home.Type)){
                r5ViewController  = mClass.init()

                self.addChildViewController(r5ViewController!)
                self.view.addSubview(r5ViewController!.view)
    
                //r5ViewController!.view.autoresizesSubviews = false
                //r5ViewController!.view.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth];
            }

        }

    
    }
    
    func showInfo(){
        let alert = UIAlertView()
        alert.title = "Info"
        alert.message = self.detailItem!["description"] as? String
        alert.addButton(withTitle: "OK")
        alert.show()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    
    override func viewWillDisappear(_ animated: Bool) {
       closeCurrentTest()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    func closeCurrentTest(){
        
        if( r5ViewController != nil ){
            r5ViewController!.closeTest()
            r5ViewController = nil
        }
        
    }
    
    var shouldClose:Bool{
        get{
            if(r5ViewController != nil){
                return (r5ViewController?.shouldClose)!
            }
            else{
                return true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        //self.view.autoresizesSubviews = true
        self.navigationController?.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    open override var shouldAutorotate:Bool {
        get {
            return true
        }
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return [UIInterfaceOrientationMask.all]
        }
    }

    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
}

