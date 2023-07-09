# Pandoc as Service

## Use the Repository

- Fork this repository.
- The directory `manuscript` is an example project.
    - Use the file `pandoc.yaml` in the project to specify pandoc command line arguments. See the available options in Pandoc Manual on [Defaults files](https://pandoc.org/MANUAL.html#defaults-files)
    - Push and wait the workflow "Pandoc" to create the output files as artifacts.
- Duplicate `manuscript` to convert multiple projects at once.

## Use the Docker Image

```
docker run --rm \
    --volume "$(pwd):/data" \
    --user "$(id -u):$(id -g)" \
    ghcr.io/doitian/pandoc-ide \
    -i test.md -o test.html
```

## Packaged Defaults and Filters

This repository and the docker image has packaged [my Pandoc defaults, filters, and resources](https://github.com/doitian/dotfiles-public/tree/master/pandoc).

For example, to use options file `latex.yaml` for LaTeX and PDF, add the command line arguments `-d latex`:

```
docker run --rm \
    --volume "$(pwd):/data" \
    --user "$(id -u):$(id -g)" \
    ghcr.io/doitian/pandoc-ide \
    -d latex -i test.md -o test.pdf
```
