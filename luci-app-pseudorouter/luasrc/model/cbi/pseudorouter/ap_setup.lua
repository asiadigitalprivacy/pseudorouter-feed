local nw   = require "luci.model.network"
local uci  = require "luci.model.uci".cursor()
local http = require "luci.http"
local pr   = require "luci.pseudorouter"

local form = {
	device      = pr.radiodev,
	ssid        = http.formvalue("ssid"),
	channel     = http.formvalue("channel"),
	mode        = http.formvalue("mode"),
	bssid       = http.formvalue("bssid"),
	wep         = http.formvalue("wep"),
	wpa_suites	= http.formvalue("wpa_suites"),
	wpa_version = http.formvalue("wpa_version")
}

local iw = luci.sys.wifi.getiwinfo(http.formvalue("device"))

if not iw then
	luci.http.redirect(luci.dispatcher.build_url("admin/wifi"))
	return
end

m = SimpleForm("network", translate("Setup Access Point"))
m.cancel = translate("Back to overview")

function m.on_cancel()
	local dev = http.formvalue("device")
	http.redirect(luci.dispatcher.build_url("admin/ap"))
end

nw.init(uci)

m.hidden = form


ssid = m:field(Value, "ssid", translate("AP network name (<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>)"))
ssid.default = "PR"
ssid.optional = False

function ssid.parse(self, section)
    if ssid:formvalue(section) == "" then
		self.error = { [section] = "missing" }
    end
end



key = m:field(Value, "key", translate("WPA2 Passphrase"), translate("Specify the secret encryption key here."))
key.password = true
key.datatype = "wpakey"
key.optional = False

function key.parse(self, section)
	local net

	local wdev = nw:get_wifidev(m.hidden.device)

    if not wdev then
        return
    end

	wdev:set("disabled", false)
	wdev:set("channel", m.hidden.channel)

	local wconf = {
		device  = m.hidden.device,
		mode    = "ap"
    }

    if key:formvalue(section) == "" then
		self.error = { [section] = "missing" }
    else
        wconf.ssid       = ssid and ssid:formvalue(section) or ""
        wconf.encryption = "psk2"
        wconf.key        = key and key:formvalue(section) or ""
        wconf.network    = pr.apnetwork

        -- Delete wifi net
        local n
        for _, n in ipairs(wdev:get_wifinets()) do
            if n.iwdata.network == pr.apnetwork then
                wdev:del_wifinet(n)
            end
        end

        local wnet = wdev:add_wifinet(wconf)
        uci:save("wireless")

        http.redirect(luci.dispatcher.build_url("admin/ap_settings", wnet.netid))
    end
end

return m
