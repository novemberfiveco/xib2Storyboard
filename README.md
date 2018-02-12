# xib2Storyboard • [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

xib2Storyboard is a handy tool to easily convert .xib files to .storyboard without the hassle of manually copying views, losing your outlets and possibly constraints in the process.

- Maintain all outlets, outlet collections & constraints
- Maintain all other objects such as additional views or gesture recognizers
- Adds prototype cells to UITableViews


<img src="Screenshots/screenshot-app.png">


## Getting started

To run xib2Storyboard download this repo on macOS and run the xib2Storyboard.app file which is always the latest release. If you'd like to play around with the code yourself, build & run the Xcode project.

#### Prerequisites

- xib2Storyboard requires macOS 10.11 El-Capitan or higher.

#### How to use

1. Build & run the Xcode project (or run xib2Storyboard.app).
2. Add view controller .xib file(s) by using the '+' button or dragging the files on the window.
3. Enable the 'Combine to single Storyboard' checkbox to combine all .xib files into 1 .storyboard file or leave it save each .xib as a separate .storyboard file.
4. Click the Export button. If 'Combine to single Storyboard' was enabled, you will be asked where to save the new .storyboard file, if not a new .storyboard file will be created for each .xib and placed in the same folder with the same name.
5. Import the newly generated .storyboard files in your Xcode project.

Before (.xib):

<a href="Screenshots/screenshot-xib.png"><img src="Screenshots/screenshot-xib.png" alt="alt text" width="40%" height="40%"></a>

After (.storyboard):

<a href="Screenshots/screenshot-storyboard.png"><img src="Screenshots/screenshot-storyboard.png" alt="alt text" width="40%" height="40%"></a>



## Stability

This software is considered **Beta**.
It has been thoroughly tested internally at November Five but not yet used in any live products.



## Roadmap

Currently the following releases are planned:

#### xib2Storyboard 0.3.0 (TBD)

- Support for macOS Interface Builder Files

#### xib2Storyboard 0.2.0 (March 2018)

- Add .xib files to an existing .storyboard file



## Additional notes

xib2Storyboard was created by comparing the XML format of Interface Builder files. It may stop working for future versions of Xcode should Apple decide to change the XML format of .xib or .storyboard files. xib2Storyboard works and was tested using the Xcode 8 and Xcode 9 file formats. xib2Storyboard will be thoroughly tested when new beta versions of Xcode become available.



## Contact

This project is maintained by [Dries Van Schevensteen](https://github.com/driesVS)

Got any questions or ideas? We'd love to hear from you. Check out our [contributing guidelines](CONTRIBUTING.md) for ways to offer feedback and contribute.



## License

Copyright (c) [November Five BVBA](https://novemberfive.co). All rights reserved.

Licensed under the [MIT](LICENSE.txt) License.
