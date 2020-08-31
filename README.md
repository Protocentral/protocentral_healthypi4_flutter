# ProtoCentral HealthyPi v4 Connect App

This repository contains the Flutter-based codebase for the HealthyPi v4 mobile app for Android and iOS. If you're looking for the main HealthyPi 4 repo or to purchase one, please visit https://healthypi.protocentral.com/

![HealthyPi 4 App](docs/images/hpi4_screen1.jpg)  ![HealthyPi 4 App](docs/images/hpi4_screen2.jpg)

HealthyPi v4 is a HAT for the Raspberry Pi, as well as a standalone device that can measure human vital signs that are useful in medical diagnosis and treatment. HealthyPi 4 is affordable and accessible and the open source aspect means that it’s easy to expand upon.

# How to use this code

This code is based on the amazingly simple-to-use Flutter cross-platform framework that can compile native code for both Android and iOS platforms with a single codebase. For more infromation on Flutter, please check [Flutter's website](https://flutter.dev/).

Here is a simple getting started guide to start using the HealthyPi v4 app code. 

1. Download and Install [Flutter](https://flutter.dev/). For more information on how to setup flutter, check out the [Installation Guide](https://flutter.dev/docs/get-started/install). As of the time of writing this document, the HealthyPi v4 code uses **Flutter 1.20.1**.
2. Clone this repo to your local computer or download the code as a zip file using the "Code" > "Download ZIP" option. 
3. From inside your already setup Flutter environment, run the following commands

``` 
flutter pub get // Automatically gets all the dependency packages
flutter build apk // Builds APK file for Android platforms
flutter build ios // Build for iOS (only on mac)
```

4. It really is as simple as that. 

To learn more Flutter concepts, check out this nicely documented site: https://flutter.dev/docs/get-started/learn-more
   
# License Information

This product is open source! All hardware, software and documentation are open source and licensed under the terms of the following licenses:

## Hardware

All hardware is released under [Creative Commons Share-alike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/).

![CC-BY-SA-4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

## Software

All software is released under the MIT License(http://opensource.org/licenses/MIT).

## Documentation

All product documentation is released under Creative Commons Share-alike 4.0 International.

![CC-BY-SA-4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

For detailed license information, please check LICENSE.MD.

Please check [*LICENSE.md*](LICENSE.md) for detailed license descriptions.
