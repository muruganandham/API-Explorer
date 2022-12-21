//
//  ViewController.swift
//  API Explorer
//
//  Created by Muruganandham on 19/12/22.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var urlTextField: NSTextField!
    
    @IBOutlet var authTextView: NSTextView!
    
    @IBOutlet var paramTextView: NSTextView!
    
    @IBOutlet var responseTextView: NSTextView!
    
    var token = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func sendRequestButtonPressed(_ sender: Any) {
        token = authTextView.string
        if let params = paramTextView.string.isEmpty ? [:] : paramTextView.string.convertToDictionary() {
            callApi(parameters: params)
        }
    }
    
    func callApi(parameters: [String: Any]) {
        
        let urlString: String = urlTextField.stringValue
        guard let url = URL(string: urlString) else { return }
        let request = makeRequest(url, dictionary: parameters)
        sendRequest(request, onSuccess: { [weak self] response in
            DispatchQueue.main.async {
                self?.responseTextView.string = response
            }
        }, onFailure: { error in
            print(error)
        })
    }
    
    func makeRequest(_ url: URL, dictionary: [String: Any], with customToken: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        if(dictionary.count > 0) {
            request.httpMethod = "POST"
            request.httpBody = makeHTTPBody(dictionary)
        } else {
            request.httpMethod = "GET"
        }
        if !token.isEmpty {
            let bearerToken = "Bearer "+token
            request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func sendRequest(_ request: URLRequest,
                     onSuccess: @escaping(String) -> Void,
                     onFailure: @escaping(Error) -> Void,
                     customDecode: ((Data) throws -> Any)?  = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(30)
        config.timeoutIntervalForResource = TimeInterval(30)
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonResponse = String(data: data, encoding: String.Encoding.utf8) {
                    onSuccess("JSON String: \(jsonResponse)")
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    let eventParams: [String: Any] = ["URL": request.url ?? "",
                                                      "error": error!.localizedDescription,
                                                      "responseCode": httpResponse.statusCode]
                    print(eventParams)
                }
                onFailure(error!)
            }
        }
        task.resume()
    }
    
    func makeHTTPBody(_ dictionary: [String: Any]) -> Data {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            return jsonData!
        } catch {
            print(error.localizedDescription)
            return Data()
        }
    }
}

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

