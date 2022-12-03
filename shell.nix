#!/usr/bin/env nix-shell
{ pkgs ? import <nixpkgs> {} }:
let
  myAppEnv = pkgs.poetry2nix.mkPoetryEnv {
    projectDir = ./.;
  };
in myAppEnv.env.overrideAttrs ( oldAttrs: {
  buildInputs = with pkgs; [
    zola
  ];
})
