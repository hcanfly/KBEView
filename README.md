# KenBurnsEffect

The KenBurnsView takes in an array of images and displays them in a slideshow. It uses the Vision framework to detect faces in the images (much, much better than their previous face detection) and will pan and zoom to highlight them. Which is how Ken Burns brings some life to still pictures in his documentaries. If it can't find any images it will simply pan the image horizontally or vertically depending on whether the image is portrait or landscape. I have found that trying to pan to more than three faces requires either a lot of time, or really rushing. So, the view will only pan to a maximum of three faces. If it finds more than three faces it will pan to the left-most one, then the one in the center, and then the one on the right.

Note: All of the included sample images were downloaded from the Internet and may have copyrights. I strongly suggest you don't use them in any product that you distribute widely :-)


|![Screenshot](KenBurnsClip.gif)


## System Requirements

* Deployment target iOS 11.0+
* Xcode 10.0+
* Swift 4.0+


## License

KenBurnsEffect is licensed under the MIT License. See the LICENSE file for more information, but basically this is sample code and you can do whatever you want with it.