let
  pkgs =
    import
      (fetchTarball "https://github.com/NixOS/nixpkgs/archive/27285241da3bb285155d549a11192e9fdc3a0d04.tar.gz")
      { };

  tex = (
    pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-small;
    }
  );

  # Because building happens in sandbox that cannot connect to the internet
  # we need to download assets beforehand
  iris_path = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/b-rodrigues/nixbat/7c319bcdbe15e7f7182e7685b8de176a40d0bde9/iris.csv";
    hash = "sha256-2H6THCXKxIt4yxnDDY+AZRmbxqs7FndCp4MqaAR1Cpw=";
  };

  # Common python dependencies to use in my intermediary inputs
  pythonEnv = pkgs.python312.withPackages (ps: with ps; [ pandas ]);

  # Common python sources
  python_src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./python_functions.py;
  };


  # Derivation to download the raw data
  # Doesn’t really download the data is it was downloaded before
  # but instead, passes the path to the data to the function
  downloadCsv = pkgs.stdenv.mkDerivation {
    name = "download-csv";
    buildInputs =  [ pythonEnv ];
    src = python_src;
    buildPhase = ''
      python -c "
import pandas as pd
from python_scripts import download_iris

iris_raw = download_iris('${iris_path}')

iris_raw.to_csv('iris_raw.csv', index=False)
      "
    '';
    installPhase = ''
      mkdir -p $out
      cp iris_raw.csv $out/
    '';
  };

  # Derivation to clean CSV file using Python
  cleanCsv = pkgs.stdenv.mkDerivation {
    name = "clean-csv";
    buildInputs =  [ pythonEnv ];
    src = python_src;
    buildPhase = ''
      python -c "
import pandas as pd
from python_scripts import process_iris

iris = process_iris('${downloadCsv}/iris_raw.csv')

iris.to_csv('iris.csv', index=False)
      "
    '';
    installPhase = ''
      mkdir -p $out
      cp iris.csv $out/
    '';
  };

  # Derivation to generate the plot from the CSV using R
  generatePlot = pkgs.stdenv.mkDerivation {
    name = "generate-plot";
    buildInputs = with pkgs; [
      R
      rPackages.ggplot2
      rPackages.janitor
    ];
    dontUnpack = true;
    buildPhase = ''
            Rscript -e "

      library(ggplot2)
      library(janitor)

      iris <- read.csv('${cleanCsv}/iris.csv') |>
        clean_names() |>
        transform(species = as.character(species))

      p <- ggplot(iris, aes(x = sepal_length, y = sepal_width, color = species)) +
          geom_point(size = 3) +                
          labs(title = 'Sepal Length vs Sepal Width',
               x = 'Sepal Length',           
               y = 'Sepal Width') +           
          theme_minimal() +                         
          theme(plot.title = element_text(hjust = 0.5)) 


      ggsave('plot.png', plot = p, width = 6, height = 4, dpi = 300)

      "
    '';
    installPhase = ''
      mkdir -p $out
      cp plot.png $out/
    '';
  };

in
# Derivation to generate the HTML report from Markdown
pkgs.stdenv.mkDerivation {
  name = "generate-report";
  buildInputs = [
    pkgs.quarto
    tex
  ];
  src = pkgs.lib.fileset.toSource {
        root = ./.;
        # Only include report.Qmd in the source
        fileset = ./report.Qmd;
  };
  buildPhase = ''

    cp ${generatePlot}/plot.png .

    # Deno needs to add stuff to $HOME/.cache
    # so we give it a home to do this
    mkdir home
    export HOME=$PWD/home
    quarto render report.Qmd --to pdf

  '';

  installPhase = ''
    mkdir -p $out
    cp report.pdf $out/
  '';
}
