# Ariel Richtman blog

Contains Zola theme + content for my blog

[![Netlify Status](https://api.netlify.com/api/v1/badges/8f94c53a-9d4f-4f62-aa11-cdcc6b741442/deploy-status)](https://app.netlify.com/sites/darling-muffin-a39ab1/deploys)

## Authoring

When updating an article one you can use `date -Iseconds` and update frontmatter date property.

## Development

Use the Nix Flake to enter development environment.

*Note: Presently the flake is installing a version of Zola that doesn't play well with the DeepThought scss.*
Nixpkgs is great except for installing older package versions.
The workaround is to run a container `docker run --network host  --rm -it -v $(pwd):/workdir thibaultmorin/zola:0.16 serve`

## Issues

- I don't like overriding the index content block to style the text centered, we'll miss important updates to the theme.
  However it's hardly worth exposing as a config item upstream.
