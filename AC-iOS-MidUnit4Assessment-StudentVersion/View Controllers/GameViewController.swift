//  GameViewController.swift
//  AC-iOS-MidUnit4Assessment-StudentVersion
//  Created by C4Q on 12/22/17.
//  Copyright © 2017 C4Q . All rights reserved.

import UIKit

class GameViewController: UIViewController, UITextFieldDelegate {

	//MARK: Outlets
	@IBOutlet weak var gameCollectionView: UICollectionView! {
		didSet {
			gameCollectionView.delegate = self
			gameCollectionView.dataSource = self
		}
	}
	@IBOutlet weak var instructionsLabel: UILabel!
	@IBOutlet weak var stopButton: UIButton!
	@IBOutlet weak var drawCardButton: UIButton!
	@IBOutlet weak var handValueLabel: UILabel!
	@IBOutlet weak var changeWinValue: UITextField! {
		didSet {
			changeWinValue.delegate = self
		}
	}

	//MARK: View Overrides
	override func viewDidLoad() {
		super.viewDidLoad()
		if let winningScore = UserDefaultsHelper.manager.getWinningNumber() {
			self.winningScore = winningScore
		}
		resetGame()
	}

	//MARK: Properties
	let cellSpacing = UIScreen.main.bounds.size.width * 0.05
	var deck: Deck! {
		didSet { getCard(fromDeckID: deck.deckId) }
	}
	var card: Card!
	var playerCards = [Card]() {
		didSet { gameCollectionView.reloadData()}
	}
	var playerScore = 0
	var winningScore = 0 {
		didSet {
			instructionsLabel.text = "Get as close to \(winningScore) without going over!"
		}
	}
	var gameOver: Bool = false


	//MARK: Actions
	@IBAction func stop(_ sender: UIButton) {
		gameOver = true
		updateDisplayScore()
		showGameOverAlert()
	}
	@IBAction func drawCard(_ sender: UIButton) {
		getCard(fromDeckID: deck.deckId)
		playerCards.append(card)
		playerScore += card.cardValueInt
		updateDisplayScore()
		if playerScore >= 30 {
			gameOver = true
			showGameOverAlert()
		}
	}





}

//MARK: Methods
extension GameViewController {
	private func getDeck(){
		let printErrors = {(error: Error) in print(error)}
		DeckAPIClient.manager.getDeck(completionHandler: { (onlineDeck) in
			self.deck = onlineDeck
		}, errorHandler: printErrors)
	}

	private func getCard(fromDeckID: String){
		let printErrors = {(error: Error) in print(error)}
		CardAPIClient.manager.getCard(fromDeckID: deck.deckId, completionHandler: { (onlineCard) in
			self.card = onlineCard
		}, errorHandler: printErrors)
	}

	private func showGameOverAlert(){
		var message: String = ""
		var title: String = ""
		if playerScore == winningScore {
			title = "You Win!!!"
			message = "You got a perfect Score: \(self.playerScore)"
		} else if playerScore > winningScore {
			title = "Defeat"
			message = "You went over by \(self.playerScore - winningScore)"
		} else {
			title = "Game Over"
			message = "You were \(winningScore - self.playerScore) from \(winningScore)"
		}
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "Restart Game", style: .default) { (action:UIAlertAction!) in
			self.SaveGame()
			self.resetGame()
		}
		alertController.addAction(okAction)
		present(alertController, animated: true, completion: nil)
	}

	private func SaveGame(){
		let game: SavedGame = SavedGame.init(cards: playerCards, score: playerScore)
		DataModel.manager.addGameToHistory(game: game)
	}

	private func resetGame(){
		playerScore = 0
		playerCards.removeAll()
		getDeck()
		gameOver = false
		handValueLabel.text = "Current Hand Value: 00"
	}

	private func updateDisplayScore() {
		if !gameOver {
			handValueLabel.text = "Current Hand Value: \(playerScore)"
		} else {
			switch playerScore {
				case winningScore: handValueLabel.text = "Current Hand Value: \(playerScore). WIN!!"
				case (winningScore+1)...(winningScore+10): handValueLabel.text = "Current Hand Value: \(playerScore). BUST!"
				case (winningScore-3)..<winningScore: handValueLabel.text = "Current Hand Value: \(playerScore). CLOSE"
				default: handValueLabel.text = "Current Hand Value: \(playerScore). Try Again"
			}
		}
	}
}


//MARK: CollectionView - Datasource
extension GameViewController: UICollectionViewDataSource {
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return playerCards.count
	}
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCell
		let currentCard = playerCards[indexPath.row]
		cell.valueLabel.text = "\(currentCard.cardValueInt)"
		cell.cardImage.image = nil ?? #imageLiteral(resourceName: "placeholder-image")
		cell.cardImage.image = currentCard.cardImage
		return cell
	}
}

//MARK: CollectionView - Delegate Flow Layout
extension GameViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let numCells: CGFloat = 2.0
		let numSpaces: CGFloat = numCells + 1
		let screenWidth = UIScreen.main.bounds.width
		return CGSize(width: (screenWidth - (cellSpacing * numSpaces)) / numCells, height:
			collectionView.bounds.height - (cellSpacing * 2))
	}
	//// padding around our collection view
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: cellSpacing, left: cellSpacing, bottom: 0, right: cellSpacing)
	}
	//// padding between cells / items
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return cellSpacing
	}
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return cellSpacing
	}
}

extension GameViewController {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		becomeFirstResponder()
//		winningScore = Int(changeWinValue.text!)!
		UserDefaultsHelper.manager.setWinningNumber(value: Int(changeWinValue.text!)!)
		if let winningScore = UserDefaultsHelper.manager.getWinningNumber() {
			self.winningScore = winningScore
		}
		instructionsLabel.text = "Get as close to \(winningScore) without going over!"
		textField.text = ""
		resignFirstResponder()
		return true
	}
}
