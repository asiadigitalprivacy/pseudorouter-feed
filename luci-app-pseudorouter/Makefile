include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pseudorouter
PKG_RELEASE:=1

LUCI_TITLE:=Pseudorouter web module for LuCi web interface
LUCI_DEPENDS:=+luci-mod-admin-full +luci-app-firewall +tor-pr

PKG_BUILD_DEPENDS:=iwinfo

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-pseudorouter/conffiles
	/etc/config/pseudorouter
endef


# call BuildPackage - OpenWrt buildroot signature

