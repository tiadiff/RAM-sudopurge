#!/bin/bash

APP_NAME="RAMMonitor"
SRC="main.swift"
ICON_SCRIPT="make_icon.swift"
OUT_DIR="$APP_NAME.app/Contents"
MACOS_DIR="$OUT_DIR/MacOS"
RES_DIR="$OUT_DIR/Resources"

echo "Building $APP_NAME..."

# 1. Clean previous build
rm -rf "$APP_NAME.app"
rm -rf "$APP_NAME.iconset"
rm -f "$ICON_SCRIPT"
rm -f "$APP_NAME.icns"

# 2. Create Directory Structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RES_DIR"
mkdir -p "$APP_NAME.iconset"

# 3. Create Helper Script to Render Emoji to PNG
cat > "$ICON_SCRIPT" <<EOF
import Cocoa

let emoji = "🧹"
let sizes = [16, 32, 128, 256, 512, 1024]

for size in sizes {
    let scale = 1.0 // We will handle @2x by just generating larger sizes
    let imageSize = NSSize(width: Double(size), height: Double(size))
    let image = NSImage(size: imageSize)
    
    image.lockFocus()
    let fontSize = Double(size) * 0.8 // Slightly smaller than full box to fit
    let font = NSFont.systemFont(ofSize: CGFloat(fontSize))
    let attrs = [NSAttributedString.Key.font: font]
    let str = NSAttributedString(string: emoji, attributes: attrs)
    
    // Center it
    let textSize = str.size()
    let x = (Double(size) - textSize.width) / 2
    let y = (Double(size) - textSize.height) / 2
    
    str.draw(at: NSPoint(x: x, y: y))
    image.unlockFocus()
    
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
           
        // Naming convention for iconutil
        var filename = ""
        switch size {
        case 16: filename = "icon_16x16.png"
        case 32: filename = "icon_16x16@2x.png" // Also 32x32 standard
        case 64: filename = "icon_32x32@2x.png" // We don't have 64 explicitly in 'sizes' array above, let's fix logic below
        default: break
        }
        
        // Let's just generate specific filenames manually for clarity in the loop or outside
        // To be safe, let's just write to a specific path provided by argument or hardcode logic
    }
}
EOF

# Rewrite the Swift script to be simpler and take arguments: size, filename
cat > "$ICON_SCRIPT" <<EOF
import Cocoa
import Foundation

let args = CommandLine.arguments
guard args.count == 3 else {
    print("Usage: make_icon <size> <output_path>")
    exit(1)
}

let size = Double(args[1])!
let path = args[2]
let emoji = "🧹"

let imageSize = NSSize(width: size, height: size)
let image = NSImage(size: imageSize)

image.lockFocus()
let fontSize = size * 0.85
let font = NSFont.systemFont(ofSize: CGFloat(fontSize))
let attrs = [NSAttributedString.Key.font: font]
let str = NSAttributedString(string: emoji, attributes: attrs)

let textSize = str.size()
let x = (size - textSize.width) / 2
let y = (size - textSize.height) / 2

str.draw(at: NSPoint(x: x, y: y))
image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: path))
}
EOF

# 4. Generate Icons
echo "Generating icons..."

# icon_16x16.png
swift "$ICON_SCRIPT" 16 "$APP_NAME.iconset/icon_16x16.png"
# icon_16x16@2x.png (32x32)
swift "$ICON_SCRIPT" 32 "$APP_NAME.iconset/icon_16x16@2x.png"
# icon_32x32.png
swift "$ICON_SCRIPT" 32 "$APP_NAME.iconset/icon_32x32.png"
# icon_32x32@2x.png (64x64)
swift "$ICON_SCRIPT" 64 "$APP_NAME.iconset/icon_32x32@2x.png"
# icon_128x128.png
swift "$ICON_SCRIPT" 128 "$APP_NAME.iconset/icon_128x128.png"
# icon_128x128@2x.png (256x256)
swift "$ICON_SCRIPT" 256 "$APP_NAME.iconset/icon_128x128@2x.png"
# icon_256x256.png
swift "$ICON_SCRIPT" 256 "$APP_NAME.iconset/icon_256x256.png"
# icon_256x256@2x.png (512x512)
swift "$ICON_SCRIPT" 512 "$APP_NAME.iconset/icon_256x256@2x.png"
# icon_512x512.png
swift "$ICON_SCRIPT" 512 "$APP_NAME.iconset/icon_512x512.png"
# icon_512x512@2x.png (1024x1024)
swift "$ICON_SCRIPT" 1024 "$APP_NAME.iconset/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$APP_NAME.iconset"
cp "$APP_NAME.icns" "$RES_DIR/"

# Cleanup Icon artifacts
rm -rf "$APP_NAME.iconset"
rm -f "$ICON_SCRIPT"
rm -f "$APP_NAME.icns"

# 5. Compile Swift Code
echo "Compiling..."
# Using system swiftc
swiftc "$SRC" -o "$MACOS_DIR/$APP_NAME" -target x86_64-apple-macos12.0

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# 6. Create Info.plist with Icon
cat > "$OUT_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.calise.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Build successful! $APP_NAME.app updated with Emoji Icon and Status Bar."
