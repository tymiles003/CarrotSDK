![Carrot Logo](http://temp.boxedfolder.com/smartlogo_carrot.png =476x)            

[![Build Status](https://travis-ci.org/CarrotBMS/CarrotSDK.svg?branch=master)](https://travis-ci.org/CarrotBMS/CarrotSDK)            

# What is Carrot?

Carrot is the beacon management system for everyone. This is the corresponding iOS SDK. It syncs with the Carrot beacon management system, ranges beacons and triggers appropriate events. All beacon data is persisted locally. Thus, Beacon ranging und event triggering even works in environments with weak mobile connectivity. In order to support iBeacons the minimum deployment target is _iOS 7_.

# How to get started?

+ Download the project and try out the included iOS example app.
+ Integrate the framework into your own project.
+ Run the carrot beacon management system and connect it to your app.

_See the Carrot repository to deploy your own copy of the beacon management system._

## Installation

The following installation choices are available:

+ Build the CarrotSDK.framework file via the corresponding project target (iOS 8+) and add it to your project.
+ Add all files inside folder _Source_ and _Vendor/AFNetworking/AFNetworking_ to your project.
+ Install via CocoaPods by adding ´pod 'CarrotSDK'´ to your _podfile_.

## Integration & Features

...

# Example

The includes example project (CarrotExample) is located inside the _Example_ folder. It demonstrates possible implementations and features. It's the perfect spot to determine how to utilize most of the SDK methods and see what they do in the context of a 'real world' application.

# What's next?

The following features are still missing:

+ __Support for binary files__ - Carrot's current support for text and notifications should be extended to allow file attachments. The syncing process needs to be overhauled for that purpose.

# License

Carrot is released under version 3 of the [GPL](http://www.gnu.org/licenses/gpl-3.0.en.html) or any later version.
