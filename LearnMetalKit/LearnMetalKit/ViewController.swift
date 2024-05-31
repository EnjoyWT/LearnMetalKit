//
//  ViewController.swift
//  LearnMetalKit
//  Created by JoyTim on 2024/5/21
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//
    
import UIKit

// HomeViewController.swift
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // 手动记录的练习 ViewController 类名数组
    let practiceViewControllers: [String] = {
        // 设定范围，例如 1 到 10
        let range = 1 ... 5
        return range.map { "Day\($0)" }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tableView = UITableView(frame: self.view.bounds)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.practiceViewControllers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = self.practiceViewControllers[indexPath.row]
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let className = self.practiceViewControllers[indexPath.row]
        if let vcClass = NSClassFromString("LearnMetalKit.\(className)") as? UIViewController.Type {
            let viewController = vcClass.init()
            self.navigationController?.pushViewController(viewController, animated: true)
        } else {
            print("Class \(className) not found.")
        }
    }
}
