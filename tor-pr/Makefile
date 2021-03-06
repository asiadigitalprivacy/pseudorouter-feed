#
# Copyright (C) 2008-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tor-pr
PKG_VERSION:=0.2.5.12
PKG_RELEASE:=1

PKG_SOURCE:=tor-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://www.torproject.org/dist \
	https://archive.torproject.org/tor-package-archive
PKG_MD5SUM:=89745069a7efb7aafd01ae263bd0fe5c
PKG_MAINTAINER:=Hauke Mehrtens <hauke@hauke-m.de>
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=libminiupnpc libnatpmp
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/tor-pr/Default
  SECTION:=net
  CATEGORY:=Network
  URL:=https://www.torproject.org/
  USERID:=tor=52:tor=52
endef

define Package/tor-pr/Default/description
 Tor is a toolset for a wide range of organizations and people that want to
 improve their safety and security on the Internet. Using Tor can help you
 anonymize web browsing and publishing, instant messaging, IRC, SSH, and
 more. Tor also provides a platform on which software developers can build
 new applications with built-in anonymity, safety, and privacy features.
endef

define Package/tor-pr
$(call Package/tor-pr/Default)
  TITLE:=An anonymous Internet communication system (PR)
  DEPENDS:=+libevent2 +libopenssl +libpthread +librt
endef

define Package/tor-pr/description
$(call Package/tor-pr/Default/description)
 This package contains the tor daemon.
endef

define Package/tor-pr-geoip
$(call Package/tor-pr/Default)
  TITLE:=GeoIP db for tor (PR)
  DEPENDS:=+tor-pr
endef

define Package/tor-pr-geoip/description
$(call Package/tor-pr/Default/description)
 This package contains a GeoIP database mapping IP addresses to countries.
endef

define Package/tor-pr/conffiles
/etc/tor/torrc
endef

define Build/Prepare
	tar xzf "$(DL_DIR)/$(PKG_SOURCE)" -C "$(PKG_BUILD_DIR)"
	mv -f "$(PKG_BUILD_DIR)"/*/* "$(PKG_BUILD_DIR)"
	patch -p1 -d "$(PKG_BUILD_DIR)" < "$(PATCH_DIR)/001-torrc.patch"
	patch -p1 -d "$(PKG_BUILD_DIR)" < "$(PATCH_DIR)/002-torrc-trans-socks-control-ports.patch"
endef


CONFIGURE_ARGS += \
	--with-libevent-dir="$(STAGING_DIR)/usr" \
	--with-ssl-dir="$(STAGING_DIR)/usr" \
	--enable-upnp \
	--with-libminiupnpc-dir="$(STAGING_DIR)/usr" \
	--enable-nat-pmp \
	--with-libnatpmp-dir="$(STAGING_DIR)/usr" \
	--disable-asciidoc \
	--disable-seccomp

ifneq ($(CONFIG_SSP_SUPPORT),y)
	CONFIGURE_ARGS += \
		--disable-gcc-hardening
	MAKE_FLAGS += \
		CFLAGS="$(TARGET_CFLAGS)"
else
	MAKE_FLAGS += \
		CFLAGS="$(TARGET_CFLAGS) -fPIC"	
endif

CONFIGURE_VARS += \
	CROSS_COMPILE="yes"

define Package/tor-pr/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/tor $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/tor.init $(1)/etc/init.d/tor
	$(INSTALL_DIR) $(1)/etc/tor
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/etc/tor/torrc.sample $(1)/etc/tor/torrc
endef

define Package/tor-pr-geoip/install
	$(INSTALL_DIR) $(1)/usr/share/tor
	$(CP) $(PKG_INSTALL_DIR)/usr/share/tor/geoip $(1)/usr/share/tor/
endef

$(eval $(call BuildPackage,tor-pr))
$(eval $(call BuildPackage,tor-pr-geoip))
