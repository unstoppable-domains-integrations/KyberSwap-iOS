// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KYCSelectOptionViewControllerDelegate: class {
  func kycSelectOptionViewController(_ controller: KYCSelectOptionViewController, didSelect data: String)
  func kycSelectOptionViewControllerShouldBack(_ controller: KYCSelectOptionViewController)
}

class KYCSelectOptionViewController: UIViewController {

  fileprivate let cellID: String = "KYCSelectOptionViewControllerCellID"

  @IBOutlet weak var selectTitleLabel: UILabel!
  @IBOutlet weak var searchTextField: UITextField!

  @IBOutlet weak var noMatchingDataLabel: UILabel!
  @IBOutlet weak var dataTableView: UITableView!

  fileprivate let dataSources: [String]
  fileprivate var displayData: [String] = []
  fileprivate let titleText: String

  weak var delegate: KYCSelectOptionViewControllerDelegate?

  init(title: String, dataSources: [String]) {
    self.titleText = title
    self.dataSources = dataSources
    self.displayData = dataSources
    super.init(nibName: KYCSelectOptionViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.selectTitleLabel.text = self.titleText
    self.noMatchingDataLabel.text = NSLocalizedString("no.matching.data", value: "No matching data", comment: "")
    self.dataTableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellID)
    self.dataTableView.estimatedRowHeight = 60.0
    self.dataTableView.rowHeight = UITableViewAutomaticDimension
    self.dataTableView.delegate = self
    self.dataTableView.dataSource = self

    self.searchTextField.delegate = self
    self.noMatchingDataLabel.isHidden = true
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kycSelectOptionViewControllerShouldBack(self)
  }

  fileprivate func updateViewSearchDataDidChange() {
    let text = self.searchTextField.text ?? ""
    if text.isEmpty {
      self.displayData = self.dataSources
    } else {
      self.displayData = self.dataSources.filter { $0.uppercased().contains(text.uppercased()) }
    }
    self.dataTableView.reloadData()
    if self.displayData.isEmpty {
      self.dataTableView.isHidden = true
      self.noMatchingDataLabel.isHidden = false
    } else {
      self.dataTableView.isHidden = false
      self.noMatchingDataLabel.isHidden = true
    }
  }
}

extension KYCSelectOptionViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.delegate?.kycSelectOptionViewController(self, didSelect: self.displayData[indexPath.row])
  }
}

extension KYCSelectOptionViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.displayData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
    cell.textLabel?.text = self.displayData[indexPath.row]
    cell.textLabel?.numberOfLines = 0
    cell.textLabel?.textColor = UIColor.Kyber.mirage
    cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    cell.backgroundColor = UIColor.clear
    return cell
  }
}

extension KYCSelectOptionViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.updateViewSearchDataDidChange()
    return false
  }
}
