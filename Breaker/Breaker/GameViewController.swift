//
//  GameViewController.swift
//  Breaker
//
//  Created by 吴迪玮 on 2017/9/12.
//  Copyright © 2017年 吴迪玮. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

enum ColliderType: Int {
    case ball     = 0b0001
    case barrier  = 0b0010
    case brick    = 0b0100
    case paddle   = 0b1000
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var game = GameHelper.sharedInstance
    var scnScene: SCNScene!
    
    var horizontalCameraNode: SCNNode!
    var verticalCameraNode: SCNNode!
    
    var ballNode: SCNNode!
    var paddleNode: SCNNode!
    
    var lastContactNode: SCNNode!
    
    var floorNode: SCNNode!
    
    var touchX: CGFloat = 0
    var paddleX: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let deviceOrientation = UIDevice.current.orientation
        switch(deviceOrientation) {
        case .portrait:
            scnView.pointOfView = verticalCameraNode
        default:
            scnView.pointOfView = horizontalCameraNode
        }
    }
    
    func setupScene() {
        scnView = self.view as! SCNView
        scnView.delegate = self
        scnScene = SCNScene(named: "Breaker.scnassets/Scenes/Game.scn")
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        scnScene.rootNode.addChildNode(game.hudNode)
        horizontalCameraNode = scnScene.rootNode.childNode(withName:
            "HorizontalCamera", recursively: true)!
        verticalCameraNode = scnScene.rootNode.childNode(withName:
            "VerticalCamera", recursively: true)!
        ballNode = scnScene.rootNode.childNode(withName: "Ball", recursively:
            true)!
        paddleNode = scnScene.rootNode.childNode(withName: "Paddle", recursively: true)!
        
        ballNode.physicsBody?.contactTestBitMask =
            ColliderType.barrier.rawValue |
            ColliderType.brick.rawValue |
            ColliderType.paddle.rawValue
        
        floorNode =
            scnScene.rootNode.childNode(withName: "Floor",
                                        recursively: true)!
        verticalCameraNode.constraints =
            [SCNLookAtConstraint(target: floorNode)]
        horizontalCameraNode.constraints =
            [SCNLookAtConstraint(target: floorNode)]
    }
    
    func setupSounds() {
        game.loadSound(name: "Paddle",
                       fileNamed: "Breaker.scnassets/Sounds/Paddle.wav")
        game.loadSound(name: "Block0",
                       fileNamed: "Breaker.scnassets/Sounds/Block0.wav")
        game.loadSound(name: "Block1",
                       fileNamed: "Breaker.scnassets/Sounds/Block1.wav")
        game.loadSound(name: "Block2",
                       fileNamed: "Breaker.scnassets/Sounds/Block2.wav")
        game.loadSound(name: "Barrier",
                       fileNamed: "Breaker.scnassets/Sounds/Barrier.wav")
    }
    
    //MARK: Actions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            let location = touch.location(in: scnView)
            touchX = location.x
            paddleX = paddleNode.position.x
        }
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches {
            // 1
            let location = touch.location(in: scnView)
            paddleNode.position.x = paddleX +
                (Float(location.x - touchX) * 0.1)
            // 2
            if paddleNode.position.x > 4.5 {
                paddleNode.position.x = 4.5
            } else if paddleNode.position.x < -4.5 {
                paddleNode.position.x = -4.5
            }
        }
        verticalCameraNode.position.x = paddleNode.position.x
        horizontalCameraNode.position.x = paddleNode.position.x
    }
    
    //MARK: others
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {
        
        game.updateHUD()
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld,
                      didBegin contact: SCNPhysicsContact) {
        var contactNode: SCNNode!
        if contact.nodeA.name == "Ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        if lastContactNode != nil &&
            lastContactNode == contactNode {
            return
        }
        lastContactNode = contactNode
        
        // 1
        if contactNode.physicsBody?.categoryBitMask ==
            ColliderType.barrier.rawValue {
            if contactNode.name == "Bottom" {
                game.lives -= 1
                if game.lives == 0 {
                    game.saveState()
                    game.reset()
                }
            }
            
        }
        // 2
        if contactNode.physicsBody?.categoryBitMask ==
            ColliderType.brick.rawValue {
            game.score += 1
            contactNode.isHidden = true
            contactNode.runAction(
                SCNAction.waitForDurationThenRunBlock(duration: 120) {
                    (node:SCNNode!) -> Void in
                    node.isHidden = false
            })
        }
        // 3
        if contactNode.physicsBody?.categoryBitMask ==
            ColliderType.paddle.rawValue {
            if contactNode.name == "Left" {
                ballNode.physicsBody!.velocity.xzAngle -=
                    (convertToRadians(angle: 20))
            }
            if contactNode.name == "Right" {
                ballNode.physicsBody!.velocity.xzAngle +=
                    (convertToRadians(angle: 20))
            }
        }
        // 4
        ballNode.physicsBody?.velocity.length = 5.0
    }
}
