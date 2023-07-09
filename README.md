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
