SYSTEMD_USER_UNIT_DIR ?= $(shell pkg-config systemd --variable=systemduserunitdir)

install:
	install -d $(DESTDIR)$(SYSTEMD_USER_UNIT_DIR)/
	install -m 644 gamepad-launcher.service $(DESTDIR)$(SYSTEMD_USER_UNIT_DIR)/
