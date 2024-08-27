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

  # Derivation to generate the CSV file using Python
  generateCsv = pkgs.stdenv.mkDerivation {
    name = "generate-csv";
    buildInputs = with pkgs.python312Packages; [
      scikit-learn
      pandas
    ];
    src = pkgs.lib.fileset.toSource {
          root = ./.;
          # Only include report.Qmd in the source
          fileset = ./generate_data.py;
    };
    buildPhase = ''
      python generate_data.py
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

      iris <- read.csv('${generateCsv}/iris.csv') |>
        clean_names() |>
        transform(species = as.character(target))

      p <- ggplot(iris, aes(x = sepal_length_cm, y = sepal_width_cm, color = species)) +
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
