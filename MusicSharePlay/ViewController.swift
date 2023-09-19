//
//  ViewController.swift
//  MusicSharePlay
//
//  Created by Sona Maria Jolly on 07/01/22.
//

import UIKit
import AVFoundation
import GroupActivities

class ViewController: UIViewController {

    var songPlayer = AVAudioPlayer()
    var isPaused: Bool = false
    
    var groupSession: GroupSession<ShareMusic>?
    var messenger: GroupSessionMessenger?
    
    @IBOutlet weak var playPauseBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Share Music"
        prepareSong()
        Task {
            for await session in ShareMusic.sessions() {
                configureGroupSession(session)
            }
        }
    }
    
    //Load song from main bundle
    func prepareSong() {
        do {
            if let url = Bundle.main.url(forResource: "Christmas_Jingle_Bells", withExtension: "mp3") {
                songPlayer = try AVAudioPlayer(contentsOf: url)
                songPlayer.prepareToPlay()
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(AVAudioSession.Category.playback)
                } catch let error {
                    print(error)
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    //MARK:- Music actions
    func replayMusic() {
        songPlayer.currentTime = 0
        songPlayer.play()
        changeImage()
    }
    
    func pauseMusic() {
        songPlayer.pause()
        isPaused = true
        changeImage()
    }
    
    func playMusic() {
        isPaused = false
        songPlayer.play()
        changeImage()
    }
    
    //Change play or pause icon based on playing
    func changeImage() {
        if songPlayer.isPlaying {
            playPauseBtn.image = UIImage(systemName: "pause.fill")
        } else {
            playPauseBtn.image = UIImage(systemName: "play.fill")
        }
    }

    //MARK:- IBActions
    //Restart Music
    @IBAction func restartMusic(_ sender: Any) {
        if songPlayer.isPlaying || isPaused {
            self.replayMusic()
        } else {
            self.playMusic()
        }
        self.sendMessage(Actions.restart)
    }
        
    //Play or pause music
    @IBAction func playOrPauseMusic(_ sender: Any) {
        if songPlayer.isPlaying {
            self.pauseMusic()
            self.sendMessage(Actions.pause)
        } else {
            self.playMusic()
            self.sendMessage(Actions.play)
        }
    }
    
    //Activate group activity
    @IBAction func activateGroupActivity(_ sender: Any) {
        Task {
            do {
                try await ShareMusic().activate()
            } catch {
                //error
            }
        }
    }
}

//MARK:- Share Music via SharePlay
extension ViewController {
    struct ShareMusic: GroupActivity {
        var metadata: GroupActivityMetadata {
            var metadata = GroupActivityMetadata()
            metadata.title = NSLocalizedString("Share Music", comment: "Title of group activity")
            metadata.type = .generic
            return metadata
        }
    }
    
    //Configure group sessions
    func configureGroupSession(_ groupSession: GroupSession<ShareMusic>) {
        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger
        Task.detached { [weak self] in
            for await (message, _) in messenger.messages(of: Actions.self) {
                await self?.handle(message)
            }
        }
        groupSession.join()
    }
    
    //Handle message received from sender
    func handle(_ message: Actions) {
        print(message)
        if message == .restart {
            replayMusic()
        } else if message == .pause {
            pauseMusic()
        } else if message == .play {
            playMusic()
        }
    }
        
    //Send message to recievers in group
    func sendMessage(_ message: Actions) {
        if let messenger = messenger {
            Task {
                do {
                    try await messenger.send(message)
                } catch {
                    print("Failed to send")
                }
            }
        }
    }
}
