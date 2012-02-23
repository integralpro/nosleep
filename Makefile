CONFIG=Release

PAYLOAD=NoSleep.kext NoSleep.prefPane NoSleepHelper.app

BUILDDIR=DerivedData/NoSleep/Build/Products/$(CONFIG)

SUDO=sudo
KEXTSTAT=/usr/sbin/kextstat
KEXTUNLOAD=/sbin/kextunload
KEXTUTIL=/usr/bin/kextutil

.PHONY: all
all: binaries

.PHONY: binaries
binaries:
	xcodebuild -parallelizeTargets -workspace NoSleep/NoSleep.xcworkspace -scheme All -configuration $(CONFIG)

.PHONY: clean
clean:
	/bin/rm -rf DerivedData Delivery

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

