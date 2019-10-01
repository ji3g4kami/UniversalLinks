/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreNFC

class ComputersController: UIViewController {
  @IBOutlet weak var linkImage: UIImageView!
  
  var session: NFCNDEFReaderSession?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let tap = UITapGestureRecognizer(target: self, action: #selector(scanNFC(_:)))
    linkImage.addGestureRecognizer(tap)
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      session = nil
  }
  
  @objc func scanNFC(_ sender: UITapGestureRecognizer? = nil) {
    guard session == nil else {
        return
    }
    session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
    session?.alertMessage = "Hold your iPhone near the item to learn more about it."
    session?.begin()
  }
  
  // MARK: - Navigation
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "segueToDetail" {
      if let viewController = segue.destination as? ComputerDetailController, let item = (sender as? ComputerCell)?.item {
        viewController.item = item
      } else if let viewController = segue.destination as? ComputerDetailController, let item = sender as? Computer {
        viewController.item = item
      }
    }
  }
}

extension ComputersController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return ItemHandler.sharedInstance.items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ComputerCell
    
    // Configure the cell...
    let item = ItemHandler.sharedInstance.items[(indexPath as NSIndexPath).row]
    cell.item = item
    cell.backgroundColor = UIColor.clear
    
    return cell
  }
}

extension ComputersController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

extension ComputersController: NFCNDEFReaderSessionDelegate {
  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    if let readerError = error as? NFCReaderError {
        if readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead && readerError.code != .readerSessionInvalidationErrorUserCanceled {
            let alertController = UIAlertController(
                title: "Session Invalidated",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alertController, animated: true)
            }
        }
    }
    
    self.session = nil
  }
  
  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    guard let ndefMessage = messages.first,
        let record = ndefMessage.records.first,
        record.typeNameFormat == .absoluteURI || record.typeNameFormat == .nfcWellKnown,
        let payloadText = String(data: record.payload, encoding: .utf8),
        let html = payloadText.split(separator: "/").last else {
        return
    }
    
    if let computer = ItemHandler.sharedInstance.items.filter({ $0.path == html }).first {
      DispatchQueue.main.async { [unowned self] in
        self.performSegue(withIdentifier: "segueToDetail", sender: computer)
      }
    }
    
    self.session = nil
  }
  
  
}
