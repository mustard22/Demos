# DataPersistenceDemo
# 数据持久化（记录）

## 1.plist文件
即属性列表文件，全名是Property List，这种文件的扩展名为.plist，因此，通常被叫做plist文件。它是一种用来存储串行化后的对象的文件，用于存储程序中经常用到且数据量小而不经常改动的数据。

可以存储的类型:NSNumber，NSString，NSDate，NSData ,NSArray，NSDictionary，BOOL.

**不支持自定义对象的存储。**

plist的创建方式有两种:command + n 创建和纯代码创建,不同的创建方式使用方法也自然不同。

command + n 创建:
````
    // read bundle's plist
    if let plistPath = Bundle.main.path(forResource: "test", ofType: "plist") {
        var dataDict = NSDictionary(contentsOfFile: plistPath) as! Dictionary<String, Any>
        // var dataArray = NSArray(contentsOfFile: plistPath) as! NSArray

    // modify
        dataDict["Int"] = 1
        dataDict["String"] = "hi"
    }
````

纯代码创建:
````
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
````

需要注意的问题：如果需要存储自定义类型的数据需要先进行序列化。




## 
## 2.NSUserDefaults
用于存储用户的偏好设置、用户信息（如用户名、是否自动登录、字体大小等）。

数据自动保存在沙盒的Libarary/Preferences 目录下。

NSUserDefaults将输入的数据储存在.plist格式的文件下，这种存储方式就决定了它的安全性几乎为0，所以不建议存储一些敏感信息如:用户密码、token、加密私钥等。

它能存储的数据类型为：NSNumber（NSInteger、float、double、BOOL），NSString，NSDate，NSArray，NSDictionary，NSData。

**不支持自定义对象的存储。**

需要注意的问题:
1.NSUserDefaults存储的数据都是不可变的，想将可变数据存入需要先转为不可变才可以存储。

2.NSUserDefaults是定时把缓存中的数据写入磁盘的，而不是即时写入，为了防止在写完NSUserDefaults后程序退出导致的数据丢失，可以在写入数据后使用synchronize强制立即将数据写入磁盘。

````
/// code block:
func testUserDefaults() -> Void {
    let standard = UserDefaults.standard
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
````




## 
## 3.钥匙串（keychain）
Keychain在Mac上主要进行一些**敏感信息**存储使用 如用户名，密码，网络密码，认证令牌, Wi-Fi网络密码，VPN凭证等。 iOS 中 Keychain, 也有相同的功能实现 , **保存的信息存储在设备中, 独立于每个App沙盒之外。**

**当你删除APP后Keychain存储的数据不会删除**，所以在重装App后，Keychain里的数据还能使用。从ios 3.0开始，跨程序分享keychain变得可行而NSUserDefaults存储的数据会随着APP而删掉。

**相同的 Team ID 开发, 可实现多个App 共享数据。**

使用keychain时苹果官方已经为我们封装好了文件KeychainItemWrapper，引入即可使用。

第三方库SAMKeychain。。。
````
/// SAMKeychain 简单使用
func testKeychain() -> Void {
    let account = "479377608"
    let service = "com.qq"
    // 检测数据是否已存
    if SAMKeychain.password(forService: service, account: account) != nil {
        print("keychain exist..")
    } else {
        // 存储
        if SAMKeychain.setPassword("123456", forService: service, account: account) {
            print("keychain set success")
        } else {
            print("keychain set failed...")
        }
    }
}
````


## 
## 4.归档（NSKeyedArchiver）
归档是iOS开发中数据存储常用的技巧，归档可以直接将对象储存成文件，把文件读取成对象。

相对于plist或者NSUserDefault形式，归档可以存储的数据类型更加多样，并且可以存取自定义对象。对象归档的文件是保密的，在磁盘上无法查看文件中的内容，更加安全。

遵守NSCoding协议，并实现该协议中的两个方法。如果是继承，则子类一定要重写那两个方法。因为子类在存取的时候，会去子类中去找调用的方法，没找到那么它就去父类中找，所以最后保存和读取的时候新增加的属性会被忽略。需要先调用父类的方法，先初始化父类的，再初始化子类的。

保存数据的文件的后缀名可以随意命名。

最大的优点是：**可以将复杂的对象写入文件 可以归档集合类，所以无论添加多少对象，将对象写入磁盘的方式都是一样的，不会增加工作量。**



## 
## 5.沙盒（sandbox）
### 持久化在Document目录下，一般存储非机密数据。当App中涉及到电子书阅读、听音乐、看视频、刷图片列表等时，推荐使用沙盒存储，可以极大的节约用户流量，且增强了app的体验效果。

Application：存放程序源文件，上架前经过数字签名，上架后不可修改。

Documents: 保存应运行时生成的需要持久化的数据,iTunes同步设备时会备份该目录。例如,游戏应用可将游戏存档保存在该目录。

tmp: 保存应运行时所需的临时数据,使完毕后再将相应的文件从该目录删除。应用 没有运行时,系统也可能会清除该目录下的文件。iTunes同步设备时不会备份该目录。

Library/Caches: 保存应用运行时成的需要持久化的数据,iTunes同步设备时不会备份 该目录。一般存储体积大、不需要备份的非重要数据，比如网络数据缓存存储到Caches下

Library/Preference: 保存应用的所有偏好设置，如iOS的Settings(设置) 应会在该目录中查找应的设置信息。iTunes同步设备时会备份该目录。

````
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
````


## 
## 6.数据库（sqllite）
适合储存数据量较大的数据,一般使用FMDB等第三方库。

FMDB是iOS平台的SQLite数据库框架，FMDB以OC的方式封装了SQLite的C语言API，使用起来更加面向对象，省去了很多麻烦、冗余的C语言代码，对比苹果自带的Core Data框架，更加轻量级和灵活，提供了多线程安全的数据库操作方法，有效地防止数据混乱。

易用性不强, 但可以存储大量数据，存储、检索大量数据非常高效；能对数据进行复杂的聚合，比使用对象执行这些操作要高效得多。


## 
## 7.CoreData
Core Data是iOS5之后才出现的一个框架，它提供了对象-关系映射(ORM)的功能，即能够将OC对象转化成数据，保存在SQLite数据库文件中，也能够将保存在数据库中的数据还原成OC对象。在此数据操作期间，我们不需要编写任何SQL语句。

CoreData本质还是讲数据存在了SQLite数据库文件，使用不是很方便。

MagicalRecord是对CoreData的二次封装，使用起来简单操作方便。

