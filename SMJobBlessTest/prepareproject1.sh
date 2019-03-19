echo "Copying Helper binary to LaunchServices in App bundle"
cp Helper/com.tweaking4all.SMJobBlessHelper project1.app/Contents/Library/LaunchServices/
strip project1 project1.app/Contents/Library/LaunchServices/com.tweaking4all.SMJobBlessHelper

echo "Stripping binary"
strip project1
echo "Copying Binary to Contents/MacOS in App bundle"
cp project1 project1.app/Contents/MacOS/

echo "Signing Helper Tool in App bundle"
codesign --force --sign "Developer ID Application: John Doe (XXXXXXXXXX)" project1.app/Contents/Library/LaunchServices/com.tweaking4all.SMJobBlessHelper
echo "Signing App bundle"
codesign --force --sign "Developer ID Application: John Doe (XXXXXXXXXX)" project1.app
