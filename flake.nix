{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          name = "elm-webapi";
          packages = (with pkgs.elmPackages; [
            elm
            elm-test
            elm-format
            elm-json
          ]) ++ (with pkgs; [
            nil
            nixpkgs-fmt
            nodejs_22
          ]);
          shellHook =
            let
              settings = builtins.toJSON {
                "elmLS.elmTestPath" = "${pkgs.elmPackages.elm-test}/bin/elm-test";
                "elmLS.elmPath" = "${pkgs.elmPackages.elm}/bin/elm";
                "elmLS.elmFormatPath" = "${pkgs.elmPackages.elm-format}/bin/elm-format";
              };
            in
            ''
              mkdir -p "$PWD/.vscode"
              cat << EOF > "$PWD/.vscode/settings.json"
              ${settings}
              EOF
            '';
        };
      });
    };
}
