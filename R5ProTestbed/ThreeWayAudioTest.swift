//
//  TwoWay.swift
//  R5ProTestbed
//
//  Created by David Heimann on 3/9/16.
//  Copyright © 2016 Infrared5. All rights reserved.
//

import UIKit
import R5Streaming

@objc(ThreeWayAudioTest)
class ThreeWayAudioTest: BaseTest {
    var timer : Timer? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        AVAudioSession.sharedInstance().requestRecordPermission { (gotPerm: Bool) -> Void in };
        
        //setupDefaultR5VideoViewController()
        
        // Set up the configuration
        let config = getConfig()
        // Set up the connection and stream
        let connection = R5Connection(config: config)
        
        setupPublisher(connection: connection!)
        // show preview and debug info
        
        self.publishStream?.client = self;
        self.publishStream!.publish(Testbed.getParameter(param: "stream1") as! String, type: R5RecordTypeLive)
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ThreeWayAudioTest.handleSingleTap(_:)))
        
        self.view.addGestureRecognizer(tap)
    }
    
    override func setupPublisher(connection: R5Connection){
    
    self.publishStream = R5Stream(connection: connection)
    self.publishStream!.delegate = self
    self.publishStream!.audioController = R5AudioController(mode: R5AudioControllerModeEchoCancellation)
    if(Testbed.getParameter(param: "audio_on") as! Bool){
    // Attach the audio from microphone to stream
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    let microphone = R5Microphone(device: audioDevice)
    microphone?.bitrate = 32
    microphone?.device = audioDevice;
    NSLog("Got device %@", String(describing: audioDevice?.localizedName))
        
    self.publishStream!.attachAudio(microphone)
    }
    
    }
    
    func handleSingleTap(_ recognizer : UITapGestureRecognizer) {
        
        //change which camera is being used!!!
        
        //get front and back camera!!!!
        if(self.publishStream != nil )
        {
            self.publishStream?.pauseAudio = !self.publishStream!.pauseAudio
        }
    }
    
    func subscribe2Begin()
    {
        performSelector(onMainThread: #selector(ThreeWayAudioTest.subscribe2Trigger), with: nil, waitUntilDone: false)
    }
    
    func subscribe2Trigger()
    {
        if( subscribeStream == nil )
        {
            let config = getConfig()
            // Set up the connection and stream
            let connection = R5Connection(config: config)
            self.subscribeStream = R5Stream(connection: connection)
            self.subscribeStream!.delegate = self
            self.subscribeStream?.client = self;
            self.subscribeStream!.audioController = R5AudioController(mode: R5AudioControllerModeEchoCancellation)
            self.subscribeStream!.play(Testbed.getParameter(param: "stream2") as! String)
        }
    }
    
    func subscribe3Begin()
    {
        performSelector(onMainThread: #selector(ThreeWayAudioTest.subscribe3Trigger), with: nil, waitUntilDone: false)
    }
    
    func subscribe3Trigger()
    {
        if( subscribe2Stream == nil )
        {
            let config = getConfig()
            // Set up the connection and stream
            let connection = R5Connection(config: config)
            self.subscribe2Stream = R5Stream(connection: connection)
            self.subscribe2Stream!.delegate = self
            self.subscribe2Stream?.client = self;
            self.subscribe2Stream!.audioController = R5AudioController(mode: R5AudioControllerModeEchoCancellation)
            self.subscribe2Stream!.play(Testbed.getParameter(param: "stream3") as! String)
        }
    }
    
    var failCount: Int = 0;
    override func onR5StreamStatus(_ stream: R5Stream!, withStatus statusCode: Int32, withMessage msg: String!) {
        
        if(stream == self.publishStream){
            
            if(Int(statusCode) == Int(r5_status_start_streaming.rawValue)){
                
                self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(ThreeWayAudioTest.getStreams), userInfo: nil, repeats: false)
            }
        }
        
        if(stream == self.subscribeStream){
            if(Int(statusCode) == Int(r5_status_connection_error.rawValue)){
                failCount += 1
                if(failCount < 4){
                    self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(ThreeWayAudioTest.subscribe2Begin), userInfo: nil, repeats: false)
                    self.subscribeStream = nil
                }
                else{
                    print("The other stream appears to be invalid")
                }
            }
        }
        
        if(stream == self.subscribe2Stream){
            if(Int(statusCode) == Int(r5_status_connection_error.rawValue)){
                failCount += 1
                if(failCount < 4){
                    self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(ThreeWayAudioTest.subscribe3Begin), userInfo: nil, repeats: false)
                    self.subscribe2Stream = nil
                }
                else{
                    print("The other stream appears to be invalid")
                }
            }
        }
    }
    
    func getStreams (){
        publishStream?.connection.call("streams.getLiveStreams", withReturn: "onGetLiveStreams", withParam: nil)
    }
    
    func onGetLiveStreams (streams : String){
        
        NSLog("Got streams: " + streams)
        
        var names : NSArray
        
        do{
            names = try JSONSerialization.jsonObject(with: streams.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
        } catch _ {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ThreeWayAudioTest.getStreams), userInfo: nil, repeats: false)
            return
        }
        
        for i in 0..<names.count {
            
            if( Testbed.getParameter(param: "stream2") as! String == names[i] as! String )
            {
                subscribe2Begin()
            }
            if( Testbed.getParameter(param: "stream3") as! String == names[i] as! String )
            {
                subscribe3Begin()
            }
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ThreeWayAudioTest.getStreams), userInfo: nil, repeats: false)
    }
    
    func onMetaData(data : String){
        
    }
}
