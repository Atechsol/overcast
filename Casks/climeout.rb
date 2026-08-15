cask "climeout" do
  version "0.1.0"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_OF_RELEASE_ZIP"

  url "https://github.com/YOURNAME/climeout/releases/download/v#{version}/Climeout.app.zip"
  name "Climeout"
  desc "Lightweight floating widget showing time, weather, and dev mood"
  homepage "https://github.com/YOURNAME/climeout"

  app "Climeout.app"

  # This build is unsigned / not notarized (free, open-source distribution path).
  # This shim removes the quarantine attribute so Gatekeeper doesn't block first launch.
  postflight do
    system_command "/usr/bin/xattr",
                    args: ["-cr", "#{appdir}/Climeout.app"],
                    sudo: false
  end

  zap trash: [
    "~/.config/climeout",
  ]
end
