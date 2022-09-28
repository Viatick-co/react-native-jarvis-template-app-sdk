import Foundation

class JarvisApi {
    
    var apiHost = "https://jarvis.viatick.com/apis"
    
    func getApplicationDetail(sdkKey: String)-> Void {
        var url = URL(string: apiHost + "/account/application/detail")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Access-Token", forHTTPHeaderField: sdkKey)
        
        let applicationDetail = URLSession.shared.dataTask(with: request) {data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {                                                               // check for fundamental networking error
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // do whatever you want with the `data`, e.g.:
            
            do {
                let responseObject = try JSONDecoder().decode(ApplicationDetail.self, from: data)
                print(responseObject)
            } catch {
                print(error) // parsing error
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }
        applicationDetail.resume()
    }
    
    func findNotificationByDevice(sdkKey: String, uuid: String, major: Int, minor: Int)-> Void {
        var url = URL(string: apiHost + "/resource/locating-notification/find-by-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Access-Token", forHTTPHeaderField: sdkKey)
        let jsonData: [String: Any] = ["uuid": uuid, "major": major, "minor": minor]
        let body = try?JSONSerialization.data(withJSONObject: jsonData)
        request.httpBody = body
        
        let notification = URLSession.shared.dataTask(with: request) {data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {                                                               // check for fundamental networking error
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // do whatever you want with the `data`, e.g.:
            
            do {
                let responseObject = try JSONDecoder().decode(ApplicationDetail.self, from: data)
                print(responseObject)
            } catch {
                print(error) // parsing error
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                } else {
                    print("unable to parse response as string")
                }
            }
        }
        notification.resume()
    }
}
