/// Contains the hard-coded settings per flavor.
class FlavorSettings {
  final bool istv;
  // TODO Add any additional flavor-specific settings here.

  FlavorSettings.tv()
    : istv = true;

  FlavorSettings.phone()
    : istv = false;
}