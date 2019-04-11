CONFIG=Release

DELIVERY=Delivery
DERIVED_DATA=DerivedData
DELIVERY_AREA=$(DERIVED_DATA)/Delivery
BUILDDIR=$(DERIVED_DATA)/$(CONFIG)

KEXTSTAT=/usr/sbin/kextstat
KEXTUNLOAD=/sbin/kextunload
KEXTUTIL=/usr/bin/kextutil

TEAM="RR43DU5BN9"
NOTARIZE_LOGIN="integral.pro@gmail.com"
NOTARIZE_PASSWORD="@keychain:Notary"

.PHONY: apps
apps: $(BUILDDIR)/NoSleep.app $(BUILDDIR)/Donate.app

.PHONY: clean
clean:
	/bin/rm -rf $(DERIVED_DATA) $(DELIVERY)

$(BUILDDIR)/NoSleep.app:
	xcodebuild -parallelizeTargets -project NoSleep/NoSleep.xcodeproj -alltargets -configuration $(CONFIG)

$(BUILDDIR)/Donate.app:
	xcodebuild -parallelizeTargets -project PayPalButton/PayPalButton.xcodeproj -alltargets -configuration $(CONFIG)

.PHONY: notarize-submit
notarize-submit: $(BUILDDIR)/NoSleep.app $(BUILDDIR)/Donate.app
	/usr/bin/ditto -c -k --keepParent "$(BUILDDIR)/NoSleep.app" "$(BUILDDIR)/NoSleep.app.zip"
	xcrun altool --notarize-app --primary-bundle-id "com.protech.NoSleep" --username "$(NOTARIZE_LOGIN)" --password "$(NOTARIZE_PASSWORD)" --file "$(BUILDDIR)/NoSleep.app.zip"
	/usr/bin/ditto -c -k --keepParent "$(BUILDDIR)/Donate.app" "$(BUILDDIR)/Donate.app.zip"
	xcrun altool --notarize-app --primary-bundle-id "com.protech.NoSleep" --username "$(NOTARIZE_LOGIN)" --password "$(NOTARIZE_PASSWORD)" --file "$(BUILDDIR)/Donate.app.zip"

.PHONY: notarize-staple
notarize-staple: $(BUILDDIR)/NoSleep.app $(BUILDDIR)/Donate.app
	xcrun stapler staple -v $(BUILDDIR)/NoSleep.app
	xcrun stapler staple -v $(BUILDDIR)/Donate.app

.PHONY: notarize-submit-dmg
notarize-submit-dmg: $(DELIVERY)/NoSleep.dmg
	xcrun altool --notarize-app --primary-bundle-id "com.protech.NoSleep" --username "$(NOTARIZE_LOGIN)" --password "$(NOTARIZE_PASSWORD)" --file $<

.PHONY: notarize-staple-dmg
notarize-staple-dmg: $(DELIVERY)/NoSleep.dmg
	xcrun stapler staple -v $(DELIVERY)/NoSleep.dmg

$(DELIVERY_AREA): $(BUILDDIR)/NoSleep.app $(BUILDDIR)/Donate.app | notarize-staple
	if [[ ! -e $@ ]]; then mkdir -p $@; fi
	cp LegacyInstaller/Uninstall.command $@/Uninstall.command
	codesign -v --sign $(TEAM) $@/Uninstall.command
	cp -R $^ $@
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
	codesign -v --force --sign $(TEAM) $@
