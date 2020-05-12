//
//  ViewController.swift
//  Case2-Boilertalk-SPM
//
//  Created by Belén on 09/04/2020.
//  Copyright © 2020 IWEB. All rights reserved.
//

import UIKit
import Web3
import Web3PromiseKit
import Web3ContractABI

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var lessButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    var contract: DynamicContract!
    var account: EthereumAddress!
    var web3: Web3?
    var privateKey: EthereumPrivateKey!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.web3 = Web3(rpcURL: "HTTP://127.0.0.1:7545")
        print("Web3 configurado")
        
        let path = Bundle.main.path(forResource: "contractAbi", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let contractAbi = String(data: data, encoding: String.Encoding.utf8)!.data(using: .utf8)!
        let contractAddress = try! EthereumAddress(hex: "0xc481b3c43AF7e98c892995a48a1ebbAdd5ABaCb2", eip55: true)
        self.contract = try! self.web3!.eth.Contract(json: contractAbi, abiKey: nil, address: contractAddress)
        print("Contrato configurado")
        
        self.privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x8378ac78a30e227d1540d00187c5d4a4e81d9bbc0cb0fd24d0157529117055eb")
        
        firstly {
            self.web3!.eth.accounts()
        }.done { accounts in
            self.account = EthereumAddress(hexString: accounts.first!.ethereumValue().string!)
            print("Cuenta configurada: \(self.account!.hex(eip55: true))")
            self.getValor()
        }.catch { error in
            print(error)
        }
    }
    
    func getValor() {
        firstly {
            self.contract!["valor"]!().call()
        }.done { valor in
            print("El valor es: \(valor.first!.value)")
            self.label.text = "\(valor.first!.value)"
        }.catch { error in
            print("Error: \(error)")
        }
    }

    @IBAction func incr(_ sender: Any) {
        print("Incrementando valor")
        self.web3!.eth.getTransactionCount(address: self.account, block: .latest).then { nonce -> Promise<EthereumSignedTransaction> in
            print(nonce)
            let method = self.contract["incr"]?(self.contract.address!)
            let transaction: EthereumTransaction = method!.createTransaction(nonce: nonce, from: self.account, value: EthereumQuantity(quantity: 0.eth), gas: 210000, gasPrice: EthereumQuantity(quantity: 21.gwei))!
            return try! transaction.sign(with: self.privateKey, chainId: 1).promise
        }.then { tx in
            self.web3!.eth.sendRawTransaction(transaction: tx)
        }.done { _ in
            self.getValor()
        }.catch { error in
            print("Error: \(error)")
        }
    }
    
    @IBAction func decr(_ sender: Any) {
        print("Decrementando valor")
        self.web3!.eth.getTransactionCount(address: self.account, block: .latest).then { nonce -> Promise<EthereumSignedTransaction> in
            let method = self.contract["decr"]?(self.contract.address!)
            let transaction: EthereumTransaction = method!.createTransaction(nonce: nonce, from: self.account, value: EthereumQuantity(quantity: 0.eth), gas: 210000, gasPrice: EthereumQuantity(quantity: 21.gwei))!
            return try! transaction.sign(with: self.privateKey, chainId: 1).promise
        }.then { tx in
            self.web3!.eth.sendRawTransaction(transaction: tx)
        }.done { _ in
            self.getValor()
        }.catch { error in
            print("Error: \(error)")
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        print("Restableciendo valor")
        self.web3!.eth.getTransactionCount(address: self.account, block: .latest).then { nonce -> Promise<EthereumSignedTransaction> in
            let method = self.contract["reset"]?(self.contract.address!)
            let transaction: EthereumTransaction = method!.createTransaction(nonce: nonce, from: self.account, value: EthereumQuantity(quantity: 0.eth), gas: 210000, gasPrice: EthereumQuantity(quantity: 21.gwei))!
            return try! transaction.sign(with: self.privateKey, chainId: 1).promise
        }.then { tx in
            self.web3!.eth.sendRawTransaction(transaction: tx)
        }.done { _ in
            self.getValor()
        }.catch { error in
            print("Error: \(error)")
        }
    }
    
}

