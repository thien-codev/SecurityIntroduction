[iOS development: Security.pdf](https://github.com/thien-codev/SecurityIntroduction/files/13782982/iOS.development.Security.pdf)
iOS development: Security
Some of way to secure the iOS app:
	⁃	The secure boot
	⁃	Encryption and data protection
	⁃	Touch ID & Face ID
	⁃	Code signing
	⁃	Sandboxing
	⁃	Secure networking
	⁃	User privacy

The secure boot:
Encryption and data protection
(Even the device was lost, the data can’t be accessed or modified)

TouchID and FaceID
Biometric data (never expose to hardware or software)
TouchID API is public for developer

Code signing
	⁃	Ensure the attackers can’t get their malicious code to run
	⁃	Ensure the apps come from trusted resources
	⁃	Runtime check ensure that malicious code not injected
 
Sandboxing
	⁃	Each app is sandboxed
	⁃	Sandboxing prevents apps accessing each other’s app -> this isolation avoids damage and data loss

Security Networking
	⁃	App transport security: require iOS apps connect to BE server using  a secure TLS channel
	⁃	Switch Http to Https

User Privacy
	⁃	iOS let user configure the info is accessed and used, and user can change them inside their app setting (photo, contact or health data,..)

User data protection
	⁃	Purpose strings: request authorization by add a special key called purpose string to app info plist and leave some comment to explain why using it, NSCameraUsageDesciption
	⁃	Copy paste sensitive data (pasteboard system) shared with Multi apps in system 
	⁃	Prevent pasteboard leakage without coding -> secure textfield
	⁃	Prevent pasteboard leakage with coding -> leave UIPasteboard.general.items = [[String: Any]()] in AppDelegate Or using custom pasteboard if app want to copy paste content inside the app
	⁃	Data can leak through screenShot  -> Sensitive data should be removed before moving to background or create a splashView to overlay the screen to hide sensitive infomation

The keychain - The secure database
	⁃	Using it to save sensitive data like password, credit card,.. so on
	⁃	When device is locked -> the keychain lock

How the keychain work:
	⁃	Keychain is a secure database that can run query on it

Step to work with keychain:
	⁃	Create keychain dictionary
	⁃	Add, read, remove, retrieve, restores values. We can read add pathfile: ~/Library/Developer/CoreSimulator/Devices/3DE21016-4470-4866-B5EA-29A66F91AC39/data/Library/Keychains
Another way to protect sensitive data is File data protection
File data protection
	⁃	Ensure that sensitive data can’t be extracted from a password-protected device’s storage
	⁃	By Using Data Protection API - we can explicitly set the file protection level -> The file are accessible only when the device is unlock

There are 4 protection levels: 
No protection
Complete until first user authentication - default
Complete unless open
Complete
The file is always accessible
Files are accessible after  the user unlocks the device for the first time and after that, the files are accessible
Accessible even after locking the device - new file can be created and accessed. Ex: for background task creating file…
Accessible when user unlock the device

Secure app by using Biometrics
	⁃	TouchID
	⁃	FaceID (need to add privacy info to info.plist)

Asymmetric Cryptography APIs/Interface
	⁃	User pair of public and private key to encrypt and decrypt data
	0.	Public Key: can be shared with whomever we want to exchange data securely
	0.	Private Key: should be kept private

Let see how Asymmetric cryptography work:

How work on iOS Xcode Programming:
	⁃	How to generate a private key: by SecKeyCreateRandomKey
	⁃	Should prevent generate multiple keys for the same tag
	⁃	Define the asymmetric keys (private and public) 
	1.	Perform asymmetric encryption (need public key)
	2.	Perform asymmetric decryption (need private key)
