import Cocoa
import Foundation
import Darwin

// MARK: - Memory Monitor Logic

class MemoryMonitor {
    static func getUsedMemory() -> String {

        
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        
        var vmStats = vm_statistics64()
        var vmStatsSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size) / 4
        
        let vmKerr: kern_return_t = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmStatsSize)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &vmStatsSize)
            }
        }
        
        guard vmKerr == KERN_SUCCESS else {
            return "Error"
        }
        
        // Calculate Used Memory: (Active + Wired + Compressed) * Page Size
        // Note: 'Checking' memory reporting often varies, but this is a standard approximation for "Used"
        let active = UInt64(vmStats.active_count)
        let wired = UInt64(vmStats.wire_count)
        let compressed = UInt64(vmStats.compressor_page_count)
        // let inactive = UInt64(vmStats.inactive_count) // Usually counted as "Cached" or Available
        // let free = UInt64(vmStats.free_count)
        
        let usedPages = active + wired + compressed
        let usedBytes = usedPages * UInt64(pageSize)
        
        let usedGB = Double(usedBytes) / 1_073_741_824.0
        return String(format: "%.2f GB", usedGB)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var updateTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // 1. Self-Elevation Check
        let currentUID = getuid()
        if currentUID != 0 {
            // Not root. Relaunch with sudo.
            relaunchWithSudo()
            return
        }
        
        // 2. Setup Status Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "Initializing..."
        }
        
        constructMenu()
        updateMemoryUsage()
        
        // 3. Start Polling Timer (45 seconds)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true) { _ in
            self.updateMemoryUsage()
        }
    }
    
    func relaunchWithSudo() {
        let executablePath = Bundle.main.executablePath ?? CommandLine.arguments[0]
        let quotedPath = "'\(executablePath)'"
        
        // Improved AppleScript to run in background or just execute
        let scriptSource = "do shell script \"\(quotedPath) &> /dev/null &\" with administrator privileges"
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("Elevation failed: \(error)")
                NSApp.terminate(nil) // Fail gracefully-ish
                return
            }
        }
        
        // Quit this instance, assuming the root one launched
        NSApp.terminate(nil)
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Purge RAM", action: #selector(purgeRAM), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func updateMemoryUsage() {
        let memoryText = MemoryMonitor.getUsedMemory()
        DispatchQueue.main.async {
            self.statusItem.button?.title = memoryText
        }
    }
    
    @objc func purgeRAM() {
        // Run /usr/sbin/purge. We are root, so no password needed.
        let task = Process()
        task.launchPath = "/usr/sbin/purge"
        
        do {
            try task.run()
            task.waitUntilExit()
            // Force an immediate update after purge
            updateMemoryUsage()
        } catch {
            print("Failed to run purge: \(error)")
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
