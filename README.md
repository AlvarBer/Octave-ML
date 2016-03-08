Octave Machine Learning API
===========================

Introduction
------------

**Octave ML API** is a Machine Learning API written in Octave/MATLAB with an 
emphasis on simplicity and ease of use.

Each one of the estimators here can be used with a single line of code and has 
many arguments that can be easily tweaked under the hood such as adjustment of 
hyper-parameters, Stratified K-Fold, or train/adjust/test split.

The estimators that are implemented right now are:

* Logistic Regression
* Neural Networks
* Support Vector Machines

![Demo](https://cloud.githubusercontent.com/assets/9200682/12464641/4babce0a-bfca-11e5-8c96-3eb4b27c2307.png)

Basic requirements
------------------
The program is written in [Octave][Octave Download], so you will need to have 
it installed in your computer.

We tried to remain close to MATLAB only syntax and we will try to get to 100% 
cross-compatibility in the future, but for now there are some chunks of code 
that remain Octave-only.

Getting Started
--------------
* Checkout the source: `$ git clone https://github.com/AlvarBer/Octave-ML`
* Adapt function [getData()][getData file] to return both positive and negative examples
* Configure the parameters for each algorithm
* Comment/Uncomment the algorithms you want to use in `main.m`
* Run `$ octave main.m`

How to use
----------
```matlab
#Index Analysis using logistic regression
theta = logReg(posExamples,negExamples,lCurves);

#Index Analysis using Neural networks
theta = neuralNetwork(posExamples,posExamples,lCurves);

#Index Analysis using Support Vector Machines
model = svm(posExamples,negExamples);
```

Detailed Features
-----------------
* Enable learning curves
* Select the portion of total data to be used
* Data is equally distributed in positive and negative examples
* Normalization support
* Select distribution of examples in percentages (Training/Validation/Adjustment)
* Select range of lambda values to be used in adjustment (Only LogReg and Neural Networks)
* Select minimum degree of certainty required (Threshold)
* Select the learning rate of the learning curves (Granularity of the graphics)
* Select maximum number of iterations in the training process
* Enable selection of the best number of nodes in the hidden layer (Only Neural Networks)
* Select the range of nodes to be used in the adjustment process (Only Neural Networks)
* Select default C value (Only SVM)
* Select default sigma value (Only SVM)
* Select the range of C and sigma values to be used in the adjustment process (Only SVM)

Special Thanks to
-----------------
Fran Loza by starting the original API for his [final Machine Learning Project][BMML]

License
-------
Octave ML API is released under the MIT License. For more information, see the [License](LICENSE)

[Octave Download]: https://www.gnu.org/software/octave/download.html
[BMML]: https://github.com/franloza/BMML
[getData file]: /preprocess/preprocessing.m