# Ensure CLI passes down arguments
{ ... }@args:

import ../../lib/eval-with-configuration.nix (
  args
  // {
    configuration = [ (import ./configuration.nix) ];
    additionalHelpInstructions = { device }: ''
      You can build the `-A outputs.default` attribute to build the AsteroidOS
      smartwatch image for your watch:

       $ nix-build examples/asteroid --argstr device ${device} -A outputs.default
    '';
  }
)
