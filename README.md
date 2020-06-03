# iOS

iOS front end app


## Local setup

If you want to be sure you'll be able run the app locally, follow these steps. If you don't like this setup (e.g. you want to use a different Xcode version), you can try experimenting with that as well.

1. Install Xcode 11.0
2. Add `libstdc++.6.0.9.tdb` library to Xcode's iPhoneOS and iPhoneSimulator SDKs
    * `libstdc++.6.0.9.tdb` was removed from Xcode in the Xcode 10 release. That's why you need to add it manually. In order to do that, you can download Xcode 9.4.1 and copy these files into the same locations of Xcode 11.0:
      * `<path_to_xcode_9.4.1>/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libstdc++.6.0.9.tdb`
      * `<path_to_xcode_9.4.1>/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/libstdc++.6.0.9.tdb`
3. Install pods
4. Open `Farm POS.xcworkspace`, select the `Farmstand Cart` scheme, select a simulator running iOS 11, and run the app
5. Voila!


## Notes
* In order to fully use and test the app, you'll need a Farm Worker account and a Customer account. Please contact the app owner for those.
