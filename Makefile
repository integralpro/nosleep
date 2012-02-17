CONFIG=Release

PAYLOAD=NoSleep.kext NoSleep.prefPane NoSleepHelper.app

BUILDDIR=DerivedData/NoSleep/Build/Products/$(CONFIG)

.PHONY: all
all: binaries

.PHONY: binaries
binaries:
	xcodebuild -parallelizeTargets -workspace NoSleep/NoSleep.xcworkspace -scheme All -configuration $(CONFIG)

.PHONY: clean
clean:
	/bin/rm -rf DerivedData Delivery
