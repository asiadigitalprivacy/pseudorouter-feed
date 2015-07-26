local nw   = require "luci.model.network"
local uci  = require "luci.model.uci".cursor()
local http = require "luci.http"
local pr   = require "luci.pseudorouter"

local form = {
	device      = pr.radiodev,
	join        = http.formvalue("join"),
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

m = SimpleForm("network", translate("Join a hidden network"))
m.cancel = translate("Back to overview")
--m.reset = false

function m.on_cancel()
	local dev = http.formvalue("device")
	http.redirect(
        dev and luci.dispatcher.build_url("admin/wifi_scan") .. "?device=" .. dev
        or luci.dispatcher.build_url("admin/wifi")
    )
end

nw.init(uci)

m.hidden = form


m:field(Value, "join", translate("Network name (<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>)"))

key = m:field(Value, "key", translate("Passphrase"), translate("Specify the secret encryption key here."))
key.password = true

-- FIXME: below

function key.parse(self, section)
	local net

	local wdev = nw:get_wifidev(m.hidden.device)

	wdev:set("disabled", false)
	wdev:set("channel", m.hidden.channel)

    -- Delete wifi net
    local n
    for _, n in ipairs(wdev:get_wifinets()) do
        if n.iwdata.network == pr.clientnetwork then
            wdev:del_wifinet(n)
            break
        end
    end
    -- Delete network
    if nw:get_network(pr.clientnetwork) then
        nw:del_network(pr.clientnetwork)
    end


	local wconf = {
		device  = m.hidden.device,
		ssid    = m.hidden.join,
		mode    = (m.hidden.mode == "Ad-Hoc" and "adhoc" or "sta")
	}

	if m.hidden.wep == "1" then
		wconf.encryption = "wep-open"
		wconf.key        = "1"
		wconf.key1       = key and key:formvalue(section) or ""
	elseif (tonumber(m.hidden.wpa_version) or 0) > 0 then
		wconf.encryption = (tonumber(m.hidden.wpa_version) or 0) >= 2 and "psk2" or "psk"
		wconf.key        = key and key:formvalue(section) or ""
	else
		wconf.encryption = "none"
	end

	if wconf.mode == "adhoc" or wconf.mode == "sta" then
		wconf.bssid = m.hidden.bssid
    end


    net = nw:add_network(pr.clientnetwork, { proto = "dhcp" })

	if not net then
		self.error = { [section] = "missing" }
	else
		wconf.network = net:name()

		local wnet = wdev:add_wifinet(wconf)
		if wnet then
            uci:save("wireless")
			uci:save("network")

            http.redirect(luci.dispatcher.build_url("admin/wifi_settings", wnet.netid))
        end
	end
end

return m
