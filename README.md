# Thali Cordova Plugin

<Work on progress, not near release quality !!>
## Goals
The Thali Cordova Plugin is an easy-to-use Cordova plugin for building peer-to-peer (P2P) networking
apps on Android and iOS. 

The Thali Cordova Plugin is layered on the JXcore Cordova plugin, which uses JXcore to allow one to build
mobile applicatons in JavaScript for Node.JS.  

## Prerequisites

* For iOS, [Xcode 6](https://developer.apple.com/xcode/), or later
* For Android, [Android Studio](http://developer.android.com/sdk/index.html)

## Getting Started

### Install latest Node.JS
Follow the instructions at [https://nodejs.org/](https://nodejs.org/). When you're done, check that the
installation worked: 
```
~>   node -v
v0.12.2
~>   npm -v
2.7.4
```

### Install Cordova
(Check the [Android Platform Guide](https://cordova.apache.org/docs/en/4.0.0/guide_platforms_android_index.md.html#Android%20Platform%20Guide) 
and [iOS Platform Guide](https://cordova.apache.org/docs/en/4.0.0/guide_platforms_ios_index.md.html#iOS%20Platform%20Guide) for detailed instructions.)
```
~> sudo npm install -g cordova
```

### Create a Cordova project
```
~/Code> cordova create ThaliTest com.test.thalitest ThaliTest
```

### Android Requirements

### Use Gradle
For the command line build process, you should use gradle. Set the system environment variable `ANDROID_BUILD` to `gradle`.

### Build the P2P library to local Maven

#### Install Maven locally
Follow the instructions here: http://maven.apache.org/download.cgi
 
#### Clone the Thali Cordova Plugin library
`git clone https://github.com/thaliproject/Thali_CordovaPlugin_BtLibrary.git`  

#### Build the Thali Cordova Plugin library
At the root of the Thali Cordova Plugin:  

`gradlew build install`  

Once built the library should be visible in:  
`<user folder>\.m2\repository\org\thaliproject\p2p\btconnectorlib\btconnectorlib2\0.0.0`

### Using the Thali Cordova Plugin


#### iOS


#### Android

1. Create new project and add android platform
   * cordova create thaliTest com.test.thaliTest thaliTest
   * cd thaliTest
   * cordova platform add android
2. Fix manifest min-sdk issue
   * go to thaliTest\platforms\android and in AndroidManifest.xml change android:minSdkVersion="10" to
    android:minSdkVersion="16"
3. add the plugin
   * cordova plugin add https://github.com/thaliproject/Thali_Codovaplugin
4. Fix issue on can not replace existing file
   * from thaliTest\plugins\org.thaliproject.p2p\src\android\java\io\jxcore\node copy 
   the JXcoreExtension.java to thaliTest\platforms\android\src\io\jxcore\node 
(replace file, or copy the plug-in code and add it to existing file)
5. Add example code into the app
   * from thaliTest\plugins\org.thaliproject.p2p\sample\www copy the content 
   into thaliTest\www (replaces index.html and adds myScripts.js into the js folder, 
   and also adds app.js to the jxcore folder)
6. Add nodejs modules into the app
   * go to www\jxcore\ folder and run "npm install" (there is package.json file 
   specifying which modules are needed to be installed)
7. Remove any gz-file from the module packages (instaled by npm under the www/jxcore folder)
   * The build process fails if the gz files are present, thus search & delete them 
8. build the project 
   * cordova build android
9. run the example in device (note that for chat app, you do need at least two devices):
   * cordova run android

### Contributing
If you see a mistake, find a bug, or you think there is a better way to do something, feel free to contribute.
Email [thali-talk@thaliproject.org](mailto:thali-talk@thaliproject.org) to get started.

### License
MIT