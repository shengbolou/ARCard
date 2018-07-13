//
//  ViewController.swift
//  ARCard
//
//  Created by Shengbo Lou on 7/11/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    let webView:UIWebView = UIWebView(frame: CGRect(x: 0, y: 0, width: 1100, height: 550))
    let vNode = SKVideoNode(fileNamed: "art.scnassets/ibm.mp4")
    var userName:String!
    var phoneNumber:String!
    var emailAddress:String!
    var play:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string: "https://www.ibm.com")
        let myURLRequest:URLRequest = URLRequest(url: myURL!)
        webView.loadRequest(myURLRequest)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
        vNode.pause()
    }

    
    @objc func handleTap(rec: UITapGestureRecognizer){
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                guard let tappedNode = hits.first?.node else {
                    return
                }
                switch tappedNode.name{
                case "call":
                    guard let number = URL(string: "tel://\(self.phoneNumber!)") else { return }
                    UIApplication.shared.open(number)
                case "message":
                    guard let message = URL(string: "sms://\(self.phoneNumber!)") else {return}
                    UIApplication.shared.open(message)
                case "email":
                    guard let email = URL(string: "mailto://\(self.emailAddress!)") else {return}
                    UIApplication.shared.open(email)
                case "facetime":
                    guard let facetime = URL(string: "facetime://\(self.phoneNumber!)") else {return}
                    UIApplication.shared.open(facetime)
                case "video":
                    if play {
                        vNode.pause()
                        play = false
                    }
                    else{
                        vNode.play()
                        play = true
                    }
                default:
                    print("invalid")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARImageTrackingConfiguration()
        if let imageTrackingReference = ARReferenceImage.referenceImages(inGroupNamed: "ARR", bundle: Bundle.main) {
            configuration.trackingImages = imageTrackingReference
            configuration.maximumNumberOfTrackedImages = 1
        } else {
            print("Error: Failed to get image tracking referencing image from bundle")
        }
        //get data
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        let image : UIImage = UIImage(named:"art.scnassets/sandeep.png")!
        let imageData:NSData = image.pngData()! as NSData
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        let json: [String: Any] = ["base64": strBase64]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string: "https://bluesocr.mybluemix.net/v1/ocr/base64")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            if let responseJSON = responseJSON{
                self.userName = responseJSON!["name"]
                self.emailAddress = responseJSON!["email"]
                self.phoneNumber = responseJSON!["phone"]
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main, execute: {
                    self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                })
            }
        }
        task.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor =  anchor as? ARImageAnchor {
            let imageSize = imageAnchor.referenceImage.physicalSize
            
            let plane = SCNPlane(width: CGFloat(imageSize.width), height: CGFloat(imageSize.height))
            plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
            
            let imageHightingAnimationNode = SCNNode(geometry: plane)
            imageHightingAnimationNode.eulerAngles.x = -.pi / 2
            imageHightingAnimationNode.opacity = 0.25
            node.addChildNode(imageHightingAnimationNode)
            
            imageHightingAnimationNode.runAction(imageHighlightAction) {
                
                
                let infoScene = SKScene(fileNamed: "Info")
                let firstNameNode = infoScene?.childNode(withName: "firstName") as! SKLabelNode
                let lastNameNode = infoScene?.childNode(withName: "lastName") as! SKLabelNode
                firstNameNode.text = "Sandeep"
                lastNameNode.text = String(self.userName.split(separator: Character(" "))[1])
                infoScene?.isPaused = false
                let infoPlane = SCNPlane(width: CGFloat(imageSize.width * 1.15), height: CGFloat(imageSize.height))
                infoPlane.firstMaterial?.diffuse.contents = infoScene
                infoPlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                
                let infoNode = SCNNode(geometry: infoPlane)
                infoNode.geometry?.firstMaterial?.isDoubleSided = true
                infoNode.eulerAngles.x = -.pi / 2
                infoNode.position = SCNVector3Zero
                node.addChildNode(infoNode)
                let moveAction = SCNAction.move(by: SCNVector3(imageSize.width*1.15, 0, 0), duration: 0.3)
                
                infoNode.runAction(moveAction, completionHandler: {
                    //video view
                    self.vNode.size = CGSize(width: 1024, height: 550)
                    self.vNode.position = CGPoint(x: 1024/2, y: 550/2)
                    
                    let videoSecne = SKScene(size: CGSize(width: 1024, height: 550))
                    videoSecne.addChild(self.vNode)
                    
                    let videoPlane = SCNPlane(width: CGFloat(imageSize.width*2.3), height: CGFloat(imageSize.height*2.6))
                    videoPlane.firstMaterial?.diffuse.contents = videoSecne
                    videoPlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                    let videoNode = SCNNode(geometry: videoPlane)
                    videoNode.geometry?.firstMaterial?.isDoubleSided = true
                    videoNode.eulerAngles.x = -.pi / 2
                    videoNode.position = SCNVector3Zero
                    videoNode.name = "video"
                    node.addChildNode(videoNode)
                    let videoMoveAction = SCNAction.move(by:SCNVector3(imageSize.width*0.6, 0, -imageSize.height*2) ,duration: 0.3)
                    videoNode.runAction(videoMoveAction, completionHandler: {
                        self.vNode.play()
                        self.play = true
                        //webview
                        let webPlane = SCNPlane(width: CGFloat(imageSize.width*2.3), height: CGFloat(imageSize.height*2.6))
                        webPlane.firstMaterial?.diffuse.contents = self.webView
                        let webNode = SCNNode(geometry: webPlane)
                        webNode.geometry?.firstMaterial?.isDoubleSided = true
                        webNode.eulerAngles.x = -.pi / 2
                        webNode.position = SCNVector3Zero
                        node.addChildNode(webNode)
                        let webMoveAction = SCNAction.move(by:SCNVector3(imageSize.width*0.6, 0, imageSize.height*3) ,duration: 0.3)
                        webNode.runAction(webMoveAction, completionHandler: {
                            //buttons
                            let distances = [
                                "Call" : -imageSize.width/3.5,
                                "Message" : imageSize.width/3.5,
                                "Email" : imageSize.width*1.5,
                                "FaceTime" : imageSize.width*0.9
                            ]
                            for type in distances.keys{
                                let btnScene = SKScene(fileNamed: type)
                                btnScene?.isPaused = false
                                let btnPlane = SCNPlane(width: CGFloat(imageSize.width/3), height: CGFloat(imageSize.height/1.5))
                                btnPlane.firstMaterial?.diffuse.contents = btnScene
                                btnPlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                                
                                let btnNode = SCNNode(geometry: btnPlane)
                                btnNode.geometry?.firstMaterial?.isDoubleSided = true
                                btnNode.eulerAngles.x = -.pi / 2
                                btnNode.position = SCNVector3Zero
                                btnNode.name = type.lowercased()
                                node.addChildNode(btnNode)
                                let btnMoveAction = SCNAction.move(by: SCNVector3(distances[type]!, 0, imageSize.height*1.15), duration: 0.3)
                                btnNode.runAction(btnMoveAction, completionHandler:{
                                    if type == "FaceTime"{
                                        // one man stand
                                        let logoScene = SCNScene(named: "art.scnassets/RP_Man_Dennis_0263_30k.OBJ")!
                                        
                                        let logoNode = logoScene.rootNode.childNodes.first!
                                        logoNode.scale = SCNVector3(0.015, 0.015, 0.015)
                                        logoNode.position = SCNVector3Zero
                                        logoNode.eulerAngles.y = -.pi / 2
                                        logoNode.position.z = 0.05
                                        let material = SCNMaterial()
                                        material.diffuse.contents = UIImage(named: "art.scnassets/RP_Man_Dennis_0263_dif.jpg")
                                        logoNode.geometry?.materials = [material]
                                        node.addChildNode(logoNode)
                                    }
                                })
                                
                            }
                        })
                    })
                })
            }
            
        } else {
            print("Error: Failed to get ARImageAnchor")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("Error didFailWithError: \(error.localizedDescription)")
    }
}
