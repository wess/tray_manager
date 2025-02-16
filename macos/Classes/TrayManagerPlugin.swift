import Cocoa
import FlutterMacOS

let kEventOnTrayIconMouseDown = "onTrayIconMouseDown"
let kEventOnTrayIconMouseUp = "onTrayIconMouseUp"
let kEventOnTrayIconRightMouseDown = "onTrayIconRightMouseDown"
let kEventOnTrayIconRightMouseUp = "onTrayIconRightMouseUp"
let kEventOnTrayMenuItemClick = "onTrayMenuItemClick"

extension NSRect {
    var topLeft: CGPoint {
        set {
            let screenFrameRect = NSScreen.main!.frame
            origin.x = newValue.x
            origin.y = screenFrameRect.height - newValue.y - size.height
        }
        get {
            let screenFrameRect = NSScreen.main!.frame
            return CGPoint(x: origin.x, y: screenFrameRect.height - origin.y - size.height)
        }
    }
}

public class TrayManagerPlugin: NSObject, FlutterPlugin, NSMenuDelegate {
    var channel: FlutterMethodChannel!
    
    var statusItem: NSStatusItem = NSStatusItem();
    var statusItemMenu: NSMenu = NSMenu()
    
    var _inited: Bool = false;
    var menuItemTagDict: Dictionary<Int, String> = [:]
    var lastMenuItemTag: Int = 0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tray_manager", binaryMessenger: registrar.messenger)
        let instance = TrayManagerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "destroy":
            destroy(call, result: result)
        case "getBounds":
            getBounds(call, result: result)
            break
        case "setIcon":
            setIcon(call, result: result)
            break
        case "setToolTip":
            setToolTip(call, result: result)
            break
        case "setContextMenu":
            setContextMenu(call, result: result)
            break
        case "popUpContextMenu":
            popUpContextMenu(call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func _init() {
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.action = #selector(self.statusItemButtonClicked(sender:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp])
            button.target = self
            _inited = true
        }
    }
    
    @objc func statusItemButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        var methodName: String?
        
        switch event.type {
        case NSEvent.EventType.leftMouseDown:
            methodName = kEventOnTrayIconMouseDown
            break
        case NSEvent.EventType.leftMouseUp:
            methodName = kEventOnTrayIconMouseUp
            break
        case NSEvent.EventType.rightMouseDown:
            methodName = kEventOnTrayIconRightMouseDown
            break
        case NSEvent.EventType.rightMouseUp:
            methodName = kEventOnTrayIconRightMouseUp
            break
        default:
            break
        }
        if (methodName != nil) {
            channel.invokeMethod(methodName!, arguments: nil, result: nil)
        }
    }
    
    @objc func statusItemMenuButtonClicked(_ sender: Any?) {
        let menuItem = sender as! NSMenuItem
        
        let identifier: String = menuItemTagDict[menuItem.tag]!
        let arguments: NSDictionary = [
            "identifier": identifier,
        ]
        
        channel.invokeMethod(kEventOnTrayMenuItemClick, arguments: arguments, result: nil)
    }
    
    public func destroy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSStatusBar.system.removeStatusItem(statusItem)
        _inited = false
        result(true)
    }
    
    public func getBounds(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let frame = statusItem.button?.window?.frame;
        
        let resultData: NSDictionary = [
            "x": frame!.topLeft.x,
            "y": frame!.topLeft.y,
            "width": frame!.size.width,
            "height": frame!.size.height,
        ]
        result(resultData)
    }
    
    public func setIcon(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if !_inited { _init() }
        
        let args:[String: Any] = call.arguments as! [String: Any]
        let base64Icon: String =  args["base64Icon"] as! String;
        
        let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters)
        let image = NSImage(data: imageData!)
        image!.size = NSSize(width: 16, height: 16)
        image!.isTemplate = true
        
        if let button = statusItem.button {
            button.image = image
        }
        
        result(true)
    }
    
    public func setToolTip(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args:[String: Any] = call.arguments as! [String: Any]
        let toolTip: String =  args["toolTip"] as! String;
        
        if let button = statusItem.button {
            button.toolTip  = toolTip
        }
        
        result(true)
    }
    
    public func setContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        statusItemMenu.removeAllItems()
        
        let args:[String: Any] = call.arguments as! [String: Any]
        let menuItems: NSMutableArray = args["menuItems"] as! NSMutableArray;
        
        for item in menuItems {
            let menuItem: NSMenuItem
            
            let itemDict = item as! [String: Any]
            let identifier: String = itemDict["identifier"] as! String
            let title: String = itemDict["title"] as? String ?? ""
            let toolTip: String = itemDict["toolTip"] as? String ?? ""
            let isEnabled: Bool = itemDict["isEnabled"] as? Bool ?? true
            let isSeparatorItem: Bool = itemDict["isSeparatorItem"] as! Bool
            
            if (isSeparatorItem) {
                menuItem = NSMenuItem.separator()
            } else {
                menuItem = NSMenuItem()
            }
            
            lastMenuItemTag+=1
            
            menuItem.tag = lastMenuItemTag
            menuItem.title = title
            menuItem.toolTip = toolTip
            menuItem.isEnabled = isEnabled
            menuItem.action = isEnabled ? #selector(statusItemMenuButtonClicked) : nil
            menuItem.target = self
            
            menuItemTagDict[lastMenuItemTag] = identifier
            
            statusItemMenu.addItem(menuItem)
        }
        result(true)
    }
    
    public func popUpContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        statusItem.popUpMenu(statusItemMenu);
        result(true)
    }
}
