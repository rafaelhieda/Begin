//
//  GameOverScene.swift
//  Begin
//
//  Created by Rafael  Hieda on 04/05/15.
//  Copyright (c) 2015 Rafael Hieda. All rights reserved.
//

import Foundation
import SpriteKit
class GameOverScene: SKScene {
    
    init(size:CGSize, won: Bool) {
     
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        var message:String = won ? "You won!" : "You lose :["
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.blackColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        runAction(SKAction.sequence([SKAction.waitForDuration(1.0),SKAction.runBlock({
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let scene:SKScene = GameScene(size: size)
            self.view?.presentScene(scene, transition: reveal)
        })
    ]))
}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}