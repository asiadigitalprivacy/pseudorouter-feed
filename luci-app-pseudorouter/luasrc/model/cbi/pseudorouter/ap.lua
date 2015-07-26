

local fs = require "nixio.fs"

m = Map("pseudorouter", translate("PseudoRouter Wireless AP"),
	translate("PseudoRouter Wireless AP setup"))

s = m:section(TypedSection, "wifi", translate("Access Point"))
s.anonymous = true

o = s:option(Value, "essid", translate("ESSID"), translate("Name of the Wifi network"))


wpakey = s:option(Value, "wpa_key", translate("PSK2 passphrase"),
    translate("Specify the WPA2 secret encryption key here."))
--wpakey:depends("encryption", "psk")
--wpakey:depends("encryption", "psk2")
--wpakey:depends("encryption", "psk+psk2")
--wpakey:depends("encryption", "psk-mixed")
wpakey.datatype = "wpakey"
wpakey.rmempty = true
wpakey.password = true



return m
