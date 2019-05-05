//
//  AppDelegate.swift
//  DataPersistenceDemo
//
//  Created by walker on 2019/4/22.
//  Copyright © 2019 walker. All rights reserved.
//

import UIKit
import CoreData
import SAMKeychain


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        
        let nav = UINavigationController(rootViewController: ViewController(nibName: nil, bundle: nil))
        window?.rootViewController = nav
        
        DispatchQueue.main.async {
            self.testSandbox()
            self.testPlist()
            self.testUserDefaults()
            self.testKeychain()
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext()
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "DataPersistenceDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    @available(iOS 10.0, *)
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}



extension AppDelegate {
    //MARK: - 沙盒路径
    func testSandbox() -> Void {
        // app's home path
        let path = NSHomeDirectory()
        // document path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        // cache path
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        // library path
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
        // tmp path
        let tmpPath = NSTemporaryDirectory()
        
        // write file
        let filePath = (cachePath! as NSString).appendingPathComponent("test.txt")
        let numbers = [1,2,3] as NSArray
        if numbers.write(toFile: filePath, atomically: true) {
            print("write success.")
        } else {
            print("write failed..")
        }
        
        
        // read file
        guard let readNumbers = NSArray(contentsOfFile: filePath) else {
            print("read failed...")
            return
        }
        print(readNumbers)
        
    }
    
    //MARK: - 操作bundle里的本地plist文件
    func testBundlePlist() -> Void {
        // read
        if let plistPath = Bundle.main.path(forResource: "test", ofType: "plist") {
            var dataDict = NSDictionary(contentsOfFile: plistPath) as! Dictionary<String, Any>
            //            var dataArray = NSArray(contentsOfFile: plistPath) as! NSArray
            
            // modify
            dataDict["Int"] = 1
            dataDict["String"] = "hi"
        }
    }
    
    //MARK: - 沙盒代码创建plist
    func testPlist() -> Void {
        // create
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let plistPath = documentsPath.appendingPathComponent("test.plist")
        print(plistPath)
        
        // write
        var dict = [String: Any]()
        dict["Int"] = 1
        dict["Bool"] = true
        
        (dict as NSDictionary).write(toFile: plistPath, atomically: true)
        
        // read
        if let dataDict = NSDictionary(contentsOfFile: plistPath) {
            print(dataDict)
        }
    }
    
    //MARK: - NSUserDefaults
    func testUserDefaults() -> Void {
        let account = "479377608"
        let standard = UserDefaults.standard
        if let obj = standard.object(forKey: "account") {
            print(obj)
        } else {
            standard.set(account, forKey: "account")
            if standard.synchronize() {
                print("save success")
            } else {
                print("save failed")
            }
        }
        
        standard.set(1, forKey: "Int")
        standard.set(true, forKey: "Bool")
        standard.set(1.0, forKey: "Float")
        standard.synchronize()// 立即存储
        
        if let v_int = standard.object(forKey: "Int") {
            print("\(v_int)")
            // update
            standard.set(2, forKey: "Int")
            // remove
            standard.removeObject(forKey: "Int")
        } else {
            print("not exist")
        }
    
    }
    
    //MARK: - SAMKeychain 简单使用
    func testKeychain() -> Void {
        let account = "479377608"
        let service = "com.qq"
        if SAMKeychain.password(forService: service, account: account) != nil {
            print("keychain exist..")
        } else {
            if SAMKeychain.setPassword("123456", forService: service, account: account) {
                print("keychain set success")
            } else {
                print("keychain set failed...")
            }
        }
    }
}
