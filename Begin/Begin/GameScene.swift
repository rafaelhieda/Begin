//
//  GameScene.swift
//  Begin
//
//  Created by Rafael  Hieda on 04/05/15.
//  Copyright (c) 2015 Rafael Hieda. All rights reserved.
//

import SpriteKit
import AVFoundation

//#pragma overload de operadores

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

struct PhysicsCategory {
    static let None : UInt32 = 0
    static let All  : UInt32 = UInt32.max
    static let Monster  : UInt32 = 0b1
    static let Projectile   : UInt32 = 0b10
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    var backgroundMusicPlayer: AVAudioPlayer!
    var monstersDestroyed = 0
    
    
    override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("background-music-aac.caf")
        self.backgroundColor = SKColor.whiteColor()
        self.player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        self.addChild(player)
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        //criando o spawn de monstros
        
        self.runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
                ])
            ))
        
    }
    
    //    #pragma setando monstros
    
    
    /*gerador de posição dos monstros na SKScene */
    func random() -> CGFloat{
        
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster ()
    {
        /*criando o monstro e a posição inicial
         */
        let monster = SKSpriteNode(imageNamed: "monster")
        let actualY = self.random(min: monster.size.height/2, max: self.size.height - monster.size.height/2)
        monster.position = CGPoint(x: size.width, y: actualY)
        
        addChild(monster)
        
        //velocidade de movimentação dos monstros
        let actualDuration =  random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //determina a ação do monstro
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
    
        let actionMoveDone = SKAction.removeFromParent()
        //comentado por que fazia parte da primeira parte do tutorial
        //monster.runAction(SKAction.sequence([actionMove,actionMoveDone]))
        
        //
        let loseAction = SKAction.runBlock(){
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
            
            }
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        //
        
        
        //parte 2 do tutorial
        //setando a physics body do monstro
        
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile //seta quais categorias de objetos esse objeto deve noticiar o contact listener
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        //
        
    }
    
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        //escolhendo um dos toques para utilizá-lo
        let touch = (touches as NSSet).anyObject() as! UITouch
        let touchLocation = touch.locationInNode(self)
        
        //inicializando o projétil
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        //determinando o offset(balanceamento, compensação)
        let offset = touchLocation - projectile.position
        
    //
        if(offset.x < 0){ return }
        
        addChild(projectile)
        
        //determinando direção para atirar
        let direction = offset.normalized()
        
        //fazendo o projetil voar longe o suficiente para sair da tela
        let shootAmount = direction * 1000
        
        //adicionando a quantidade de projeteis para a posição atual
        let realDest = shootAmount + projectile.position
        
        //Criando as açoes
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove,actionMoveDone]))
        
        //setando a physicsbody do projetil
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster: SKSpriteNode)
    {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
    }
    
    //#pragma contact delegate method
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if(firstBody.categoryBitMask & PhysicsCategory.Monster != 0) && (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0) {
            projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
        }
        
        /*
            There are two parts to this method: (as duas acima)
            This method passes you the two bodies that collide, but does not guarantee that they are passed in any particular order. So this bit of code just arranges them so they are sorted by their category bit masks so you can make some assumptions later.
            Finally, it checks to see if the two bodies that collide are the projectile and monster, and if so calls the method you wrote earlier.
        */
        
        monstersDestroyed++
        
        if monstersDestroyed > 30 {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won:true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
        
        
    }
    
    func playBackgroundMusic(filename:String) {
        let url = NSBundle.mainBundle().URLForResource(filename, withExtension: nil)
        if(url == nil)
        {
            println("Não foi possivel encontrar tal arquivo: \(filename)")
            return
        }
        
        var error: NSError? = nil
        backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if backgroundMusicPlayer == nil {
            println("Não foi possível criar audio player: \(error)")
            return
        }
        
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }
   
    
}
