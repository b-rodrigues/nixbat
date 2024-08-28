# Nix as a polyglot build automation tool for data science

This repository showcases how Nix can be used to build reproducible,
polyglot, data science pipelines.

- A dataset is downloaded using a Python function;
- Some basic cleaning happens using another Python function;
- These two Python functions are defined in a Python script that could be used independently;
- The cleaned csv is then used by an R script to generate a plot using `{ggplot2}` (code is embedded in the `default.nix`);
- Finally, a Quarto Markdown file is rendered

To build, clone this repo and run `nix-build` (or better `nix-build -Q` to
hide the build phases outputs).
