# batch-counting
Demo code for the batch mode counting of "Interactive Object Counting"

This MATLAB code implements the density estimation through ridge-regression method 
from [1].
 
## Dependencies
 
* [vl_feat MATLAB library](http://www.vlfeat.org/) 
* [Peter Kovesi's MATLAB library](http://www.peterkovesi.com/matlabfns/index.html)
* [export_fig tool](https://uk.mathworks.com/matlabcentral/fileexchange/23629-export-fig) 
* (Optional) [demo dataset](http://www.robots.ox.ac.uk/~vgg/software/interactive_counting/syntheticCells.zip)

## Usage information

The main script is `demo`, which executes the configuration of the 
experiment, sets up the image database (IMDB), and runs the training and testing 
of the density estimation method on a demo dataset of synthetic cell images.
 
The configuration of the experiment is done in `getDataInfo()`, 
and it consists of setting the relevant paths (e.g. paths to raw data, annotations, 
models, etc.), and the different training and testing parameters. 
 
The image database (IMDB) is a MATLAB structure with 3 fields: train, val and test,
corresponding to the training, validation and testing sets. 
Each of them is a cell array, which contains the name of the images
and coordinates of the dot-annotations. 
For example, `imdb.test{1,1} = 'image1.jpg';` and `imdb.test{1,2} = [row1 col1 ; row2 col2; ... rowN colN]`.
An example imdb can be found in *syntheticCells/imdb.mat*.
This is also generated automatically given the annotations described below.
 
The training of the method is based on dot-annotations provided manually, 
which are stored in *.mat* files, one per image, and with the same name as its correspondent image. 
For example, for image *0001cell.png*, the annotation file is *001cell.mat* (see syntheticCells dataset provided with this package).
This *.mat* file should be a *Nx2 matrix*, with *(:,1)* being the *X* coordinates and *(:,2)* the *Y* coordinates of the annotation dots.
 
After a session of training is complete, the trained model is stored in 
the path indicated by `exppath` (in `getDataInfo()`), and it consists
of two *.mat* files. A trained model is already provided in *syntheticCells/demoOutput*.
 
When testing, the code loads the model in the path defined by `exppath`, 
and applies it to the frames defined in *imdb.test*. There are then several possible outputs. 
The main output is the file 'Results.mat', stored in 'exppath', which is a matrix with one row per frame defined in imdb.test. 
Each row has two elements, which are 1) the count based on the annotations if available (i.e. manual count), and 2) the count estimated by the method. 
 
## Additional outputs

The first additional output option, configurable in *getDataInfo()*, is mat files
containing the estimated density map for each of the frames in the testing set.
This map is such that integrating over any region of it returns the estimated 
number of object that this region contains (i.e. integrating over the entire
map gives the total number of objects. See [1] for a full explanation). 

Finally, it is possible to configure in *getDataInfo()* the output of an image showing 
the extremal region-based density visualization technique of [1] for each frame in the testing set.
Again, these images would be store in `exppath`.
 
## Demo
 
To confirm that everything is setup correctly, follow these steps:
 
* Install and setup the dependencies.
* Place the source into some path *rootpath*. 
* Run `demo`. 
 
If everything is configured properly, you should start seeing estimated 
counts in MATLAB's command window, and output files being stored in 
*/rootpath/batch-counting/syntheticCells/demoOutput*
 
## Relevant publications

* [1] C. Arteta, V. Lempitsky, J. A. Noble, A. Zisserman
Interactive Object Counting, ECCV 2014.

## License

Copyright (C) 2014-2016 by Carlos Arteta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


