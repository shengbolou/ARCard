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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.showsStatistics = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        
        sceneView.addGestureRecognizer(tap)
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
                    guard let number = URL(string: "tel://1234567890") else { return }
                    UIApplication.shared.open(number)
                case "message":
                    guard let message = URL(string: "sms://1234567890") else {return}
                    UIApplication.shared.open(message)
                case "email":
                    guard let email = URL(string: "mailto://test@test.com") else {return}
                    UIApplication.shared.open(email)
                case "facetime":
                    guard let facetime = URL(string: "facetime://1234567890") else {return}
                    UIApplication.shared.open(facetime)
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
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
                        let btnMoveAction = SCNAction.move(by: SCNVector3(distances[type]!, 0, imageSize.height), duration: 0.3)
                        btnNode.runAction(btnMoveAction)
                    }
                    
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
