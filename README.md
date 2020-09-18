# iOS

iOS front end app


## Local setup

If you want to be sure you'll be able run the app locally, follow these steps. If you don't like this setup (e.g. you want to use a different Xcode version), you can try experimenting with that as well.

1. Install Xcode 11.6
2. Install CocoaPods 1.9.3
3. Install pods
4. Open `Farm POS.xcworkspace`, select the `Farmstand Cart (DEV)` scheme, and run the app
5. Voila!


## Notes
* There are 3 schemes in the project:
  * "Farmstand Cart" - represents the production version of the app. Includes the "Farmstand Cart" target. This version is installed on the iPad in the farm stand. You can also use this scheme to test some stuff that is not testable in the development scheme, such as real Stripe payments that charge the payment card.
  * "Farmstand Card (DEV)" - represents the development version of the app. Includes the "Farmstand Cart (DEV)" target. Use this scheme for most of the development work.
  * "Swift Migration" - as the name says, this one is used for Swift migrations. The Swift migrator checks only the files in the active scheme, so this scheme includes both production and development targets.
* In order to fully use and test the app, you'll need a Farm Worker account and a Customer account, for both production and development versions of the app. Please contact the app owner for those.
