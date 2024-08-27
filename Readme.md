# Nix as a polyglot build automation tool for data science

This repository showcases how Nix can be used to build reproducible,
polyglot, data science pipelines.

- Some data is generated using Python and a .csv file is written;
- This file is then used by an R script to generate a plot using `{ggplot2}`;
- Finally, a Quarto Markdown file is rendered

To build, clone this repo and run `nix-build` (or better `nix-build -Q` to
hide the build phases outputs).
