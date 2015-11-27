CONFIG=Release

DELIVERY=Delivery
DERIVED_DATA=DerivedData
DELIVERY_AREA=$(DERIVED_DATA)/Delivery
BUILDDIR=$(DERIVED_DATA)/$(CONFIG)

SUDO=sudo
KEXTSTAT=/usr/sbin/kextstat
KEXTUNLOAD=/sbin/kextunload
KEXTUTIL=/usr/bin/kextutil

.PHONY: all
all: $(DELIVERY)/NoSleep.dmg

$(BUILDDIR)/NoSleep.app:
	xcodebuild -parallelizeTargets -project NoSleep/NoSleep.xcodeproj -alltargets -configuration $(CONFIG)

$(BUILDDIR)/Donate.app:
	xcodebuild -parallelizeTargets -project PayPalButton/PayPalButton.xcodeproj -alltargets -configuration $(CONFIG)	

.PHONY: clean
clean:
	/bin/rm -rf $(DERIVED_DATA) $(DELIVERY)

$(DELIVERY_AREA): $(BUILDDIR)/NoSleep.app $(BUILDDIR)/Donate.app
	if [[ ! -e $@ ]]; then mkdir -p $@; fi
	cp LegacyInstaller/Uninstall.command $@/Uninstall.command
	cp -r $^ $@
	ln -s /Applications/Utilities $@/Utilities

$(DELIVERY):
	if [[ ! -e $@ ]]; then mkdir -p $@; fi

$(DELIVERY)/NoSleep.dmg: $(DELIVERY_AREA) $(DELIVERY)
	if [ -e $(DERIVED_DATA)/DMG ]; then rm -rf $(DERIVED_DATA)/DMG; fi
	mkdir -p $(DERIVED_DATA)/DMG
	./Utilities/create-dmg \
		--window-size 480 340 \
		--icon-size 96 \
		--volname "NoSleep Extension" \
		--icon "Uninstall.command" 100 80 \
		--icon "NoSleep.app" 240 80 \
		--icon "Utilities" 240 220 \
		--icon "Donate.app" 380 80 \
		$(DERIVED_DATA)/DMG/NoSleep.dmg \
		$(DELIVERY_AREA)
	cp $(DERIVED_DATA)/DMG/NoSleep.dmg ./$(DELIVERY)/
