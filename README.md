## CABBaGe    ![alt text](https://github.com/TorresRC/BayesianClassifier/blob/master/CABicon20.png)

#### Classification Algorithm Based on a BAyesian method for GEnomics

An application developed in Perl that allows the classification feature extraction and bootstrapping of genomic sequences, in order to improve data visualization and usefulness for genomic applications
____

The application is built from three standalone modules:
### Bayesian Classifier, Feature Extraction and Bootstrapping

* The Bayesian Classifier, this module uses a Naive Bayes Classifier technique wich is based on the so-called Bayesian theorem and is particularly suited when the dimensionality of the inputs is high. Despite its simplicity, Naive Bayes can often outperform more sophisticated classification methods. The module classifies genomic sequences into predetermined classes using a training genome matrix of known parameters (e.g. disease, host age, host sex, geographic location, drug resistance etc.)

### How to
##### **_Note:_  In order for the CABBAGE to resume operation the input format must be comma-separated values (.csv) files**
> Three files are needed: _Training.csv, MetaData.csv and Query.csv_

> The _Training.csv_ file is a boolean table that denotes the presence or absence of a certain "feature" wich can either be a gene (Pan-genome*) or a genomic region denotated by a virtual probe (Virtual Hybridization*).

> The _MetaData.csv_ file is a table that relates each of the samples form the _Training.csv_ to predifined classes.

> The _Query.csv_ file are the samples that must be classified and they should be on the same format as in the _Training.csv_ file.


____
* The Feature Extraction, the classification has the problem of high dimensionality of feature space due to the extensive information from genomic data. This high dimensionality of feature space is solved by feature selection and feature extraction methods and improves the performance of categorization.The feature selection and feature extraction techniques remove the irrelevant features from the test and reduce the dimensionality of feature space. The module accomplishes this task by the use of a statistics test (Chi squared) extracting the most informative genes or genomic regions that make a sample belong to a particular class, the cutoff value por this procedure can be set by the user being the default p-value of 0.90.

### How to
##### **_Note:_  In order for the CABBAGE to resume operation the input format must be comma-separated values (.csv) files**
> Two files are needed: _Training.csv and MetaData.csv_

> The _Training.csv_ file is a boolean table that denotes the presence or absence of a certain "feature" wich can either be a gene (Pan-genome*) or a genomic region denotated by a virtual probe (Virtual Hybridization*).

> The _MetaData.csv_ file is a table that relates each of the samples form the _Training.csv_ to predifined classes.


____
* The Bootstrapping, the bootstrap is a tool for making statistical inferences when standard parametric assumptions are questionable. For the particular case of genomics, sample size can be an issue, such problems can be biased be the use on this module wich, generates random samples from a population with a certain distribution this way unevenness of classes can be overcome.

### How to
##### **_Note:_  In order for the CABBAGE to resume operation the input format must be comma-separated values (.csv) files**
> Three files are needed: _Training.csv, MetaData.csv and Query.csv_

> The _Training.csv_ file is a boolean table that denotes the presence or absence of a certain "feature" wich can either be a gene (Pan-genome*) or a genomic region denotated by a virtual probe (Virtual Hybridization*).

> The _MetaData.csv_ file is a table that relates each of the samples form the _Training.csv_ to predifined classes.


#### Files examples.

_Training.csv_

>|           | `Sample1` | `Sample2` | `Sample3` | `Sample4` |
>| ----------| ---: | ---:  | ---:  | ---: |
>| `Gene/Probe a` | 0 | 1 | 1 | 0 |
>| `Gene/Probe b` | 1 | 1 | 1 | 1 |
>| `Gene/Probe c` | 1 | 1 | 0 | 0 |
>| `Gene/Probe d` | 0 | 0 | 0 | 0 |
>| `Gene/Probe e` | 1 | 0 | 1 | 1 |
>| `Gene/Probe f` | 1 | 1 | 1 | 1 |

The `Samples` and `Gene/Probe` names should be determined by the user, the file can contain as many rows and columns as needed.


