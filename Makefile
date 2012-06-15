CONFIG=Release

BUILDDIR=DerivedData/NoSleep/Build/Products/$(CONFIG)

SUDO=sudo
KEXTSTAT=/usr/sbin/kextstat
KEXTUNLOAD=/sbin/kextunload
KEXTUTIL=/usr/bin/kextutil

.PHONY: all
all: delivery

.PHONY: package
package: binaries
	packagesbuild Installer/NoSleepPkg.pkgproj

.PHONY: binaries
binaries:
	xcodebuild -parallelizeTargets -workspace NoSleep/NoSleep.xcworkspace -scheme All -configuration $(CONFIG)

.PHONY: clean
clean:
	/bin/rm -rf DerivedData Delivery

.PHONY: delivery
delivery:
	$(MAKE) clean
	$(MAKE) package
	mkdir Delivery
	cat Installer/Scripts/Uninstall_1.3.1.sh > Delivery/Uninstall.command
	echo >> Delivery/Uninstall.command
	cat Installer/Scripts/Uninstall_Cli_1.3.0.sh >> Delivery/Uninstall.command
	chmod +x Delivery/Uninstall.command
	cp -r DerivedData/Installer/NoSleep.mpkg Delivery/

.PHONY: dmg
dmg: delivery
	if [ -e DerivedData/DMG ]; then rm -rf DerivedData/DMG; fi
	mkdir -p DerivedData/DMG
	./Utilities/create-dmg \
		--window-size 480 300 \
		--icon-size 96 \
		--volname "NoSleep Extension" \
		--icon "NoSleep.mpkg" 160 130 \
		--icon "Uninstall.command" 320 130 \
		DerivedData/DMG/NoSleep.dmg \
		Delivery
	cp DerivedData/DMG/NoSleep.dmg Delivery

.PHONY: dk, dkc
dkc:
	$(SUDO) $(KEXTUNLOAD) -b com.protech.NoSleep
	$(SUDO) rm -rf $(BUILDDIR)/NoSleep.kext
dk:
	#$(MAKE) clean
	#CONFIG=Debug $(MAKE) all
	#if [ "$(KEXTSTAT)|grep NoSleep" ]; then $(SUDO) $(KEXTUNLOAD) -b com.protech.NoSleep; fi
	$(SUDO) chown -R root:wheel $(BUILDDIR)/NoSleep.kext
	$(SUDO) $(KEXTUTIL) $(BUILDDIR)/NoSleep.kext

