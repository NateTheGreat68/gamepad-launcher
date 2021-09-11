UDEVDIR := $(shell pkg-config udev --variable=udevdir)/rules.d

install:
	install -d $(DESTDIR)$(UDEVDIR)/
	install -m 644 70-gamepads.rules $(DESTDIR)$(UDEVDIR)/
