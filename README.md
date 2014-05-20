# GreinerHormann
GreinerHormann.jl is an implementation of the [Greiner-Hormann](https://en.wikipedia.org/wiki/Greiner-Hormann_clipping_algorithm) polygon [clipping algorithm](https://en.wikipedia.org/wiki/Clipping_%28computer_graphics%29). In addition it uses the Hormann-Agathos algorithm to see if a [point is in a polygon](https://en.wikipedia.org/wiki/Point_in_polygon).

## References
The papers by Günther Greiner, Kai Hormann, and Alexander Agathos served as the basis for this library.

* [Greiner, Günther; Kai Hormann (1998). "Efficient clipping of arbitrary polygons". ACM Transactions on Graphics (TOG) 17 (2): 71–83.](http://dl.acm.org/citation.cfm?id=274364)
* [Hormann, K.; Agathos, A. (2001). "The point in polygon problem for arbitrary polygons". Computational Geometry 20 (3): 131. ](http://www.sciencedirect.com/science/article/pii/S0925772101000128)


## Install
This package is not yet in the Julia package repository. For now, you can call ```Pkg.clone(https://github.com/sjkelly/GreinerHormann.jl.git)``` in the Julia REPL.

## Build Status
[![Build Status](https://travis-ci.org/sjkelly/GreinerHormann.jl.svg?branch=master)](https://travis-ci.org/sjkelly/GreinerHormann.jl)

This package is being developed under the latest [development verion of Julia](https://github.com/julialang/julia). Therefore it might be incompatible with older releases.

## License
The GreinerHormann.jl package is licensed under the MIT "Expat" License. See [LICENSE.md](./LICENSE.md).
