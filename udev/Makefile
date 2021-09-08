UDEV_RULES_DIR ?= /etc/udev/rules.d

install:
	install -d $(DESTDIR)$(UDEV_RULES_DIR)/
	install -m 644 70-gamepads.rules $(DESTDIR)$(UDEV_RULES_DIR)/
