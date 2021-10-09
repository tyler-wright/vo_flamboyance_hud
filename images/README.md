# Instructions on Modifying the Crosshair

You can create the crosshair as any `.png` image file. However, in order to have
it display correctly in game you will need to convert the image to have a
premultiplied alpha using these instructions. The conversion requires
[Imagemagick](https://github.com/imagemagick/imagemagick).

1. Create a new crosshair file. In my case I've made one using
   [Inkscape](inkscape.org) and saved it as a `.svg` file. You then need to
   save it as a `.png` file.

2. Install `imagemagick` if you have not already.

3. Run the following command, where `cross.png` is your source file and
   `newrecticle.png` is your output:

      `convert cross.png -fx "u.r*a" -fx "u.g*a" -fx "u.b*a" newrecticle.png`

