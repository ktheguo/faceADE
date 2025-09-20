import UIKit

class RecordsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var records: [FaceRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        records = loadEyeClosureRecords()
//        tableView.dataSource = self
        let recordsTextView = UITextView(frame: self.view.frame)
        recordsTextView.text = records.map { "\($0.timestamp): Left Eye Min: \($0.minLeftEyeClosure), Right Eye Min: \($0.minRightEyeClosure)" }.joined(separator: "\n")
        self.view.addSubview(recordsTextView)
        
        // Add a back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
        self.view.addSubview(backButton)
    }
    
    @objc func goBack() {
            dismiss(animated: true, completion: nil)
        }


    func loadEyeClosureRecords() -> [FaceRecord] {
        if let data = UserDefaults.standard.data(forKey: "FaceRecords"),
           let records = try? JSONDecoder().decode([FaceRecord].self, from: data) {
            return records
        }
        return []
    }

    @IBAction func exportToCSV(_ sender: UIButton) {
        let csvString = createCSV(from: records)
        saveCSVFile(data: csvString)
    }

    func createCSV(from records: [FaceRecord]) -> String {
        var csvString = "User ID, Timestamp, Min Left Eye Closure, Min Right Eye Closure\n"
        for record in records {
            csvString += "\(record.userId), \(record.timestamp), \(record.minLeftEyeClosure), \(record.minRightEyeClosure)\n"
        }
        return csvString
    }

    func saveCSVFile(data: String) {
        let fileName = "FaceRecords.csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            try data.write(to: path, atomically: true, encoding: .utf8)
            print("CSV file saved at \(path)")
        } catch {
            print("Failed to save CSV file: \(error)")
        }
    }
}

extension RecordsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        let record = records[indexPath.row]
        cell.textLabel?.text = "User: \(record.userId), Time: \(record.timestamp), Left: \(record.minLeftEyeClosure), Right: \(record.minRightEyeClosure)"
        return cell
    }
}
