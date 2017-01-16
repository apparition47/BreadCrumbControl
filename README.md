# BreadCrumbControl
BreadCrumb Control for iOS written in Swift.

![sample](https://cloud.githubusercontent.com/assets/16086042/11485915/14c29ff4-97b6-11e5-9674-ff2c83a675e9.jpg)

The properties of "BreadCrumb" are fully accessible for the developer: color, animation, etc.
This control is provided with a sample application that lets you change the properties of the control in real-time.


# Compatiblity

This control is compatible with iOS 8. Swift 3.0 compatible.


# Installation in xcode project

It is a very easy control to include in your project. 

## Manually

Add to your iOS project, the two files: `BreadCrumb.swift` and `CustomButton.swift`. Add also the following resources: `button_start.png` and `button_start@2x.png` if you want to add a "Root" button at the beginning of BreadCrumb.

## CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate this into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'BreadCrumbControl', :git => 'https://github.com/apparition47/BreadCrumbControl'
end
```

# Usage

In order to use BreadCrumb control, you can instantiate it programmatically, or create a custom view in Interface Builder and assign it to an ivar of your app. Once you have an instance, you can use the control properties to configure it.


# Screenshots

screenshots of the application sample:
![sampleapplication](https://cloud.githubusercontent.com/assets/16086042/11486079/09e7d904-97b7-11e5-9cd5-e0a7e4888bfe.jpg)

# Credits

For the sample application I use the control "ColorPickerView", created by Ethan Strider on 11/28/14. This control allowed me to easily change the colors in the sample application.

The BreadCrumb and the sample application have been created by Philippe Kersalé