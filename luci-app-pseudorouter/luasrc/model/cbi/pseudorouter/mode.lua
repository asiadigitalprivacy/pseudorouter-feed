

local fs = require "nixio.fs"
local fw = require "luci.model.firewall"
local pr = require "luci.pseudorouter"

m = Map("pseudorouter", translate("PseudoRouter mode"),
	translate("Choose and configure mode: Tor, Direct or VPN"))

m.chain(m, "firewall")

fw.init(m.uci)

local uci_r = m.uci

s = m:section(TypedSection, "mode", translate("Router Mode"))
s.anonymous = true

mode = s:option(ListValue, "mode", " ")
mode.widget = "radio"
mode:value("tor", translate("Tor"))
mode:value("direct", translate("Direct"))
--mode:value("vpn", translate("VPN"))
mode.default = "tor"


function mode.parse(self, section, ...)
    local v = mode:formvalue(section)
    if v == 'direct' then
        vpn_off()
        tor_off()
        direct_on()
    end
    if v == 'tor' then
        vpn_off()
        direct_off()
        tor_on()
    end
    if v == 'vpn' then
        direct_off()
        tor_off()
        vpn_on()
    end

    ListValue.parse(self, section, ...)
end


function direct_on()
    forwarding_lan_wan_enable(true)
end
function direct_off()
    forwarding_lan_wan_enable(false)
end

function forwarding_lan_wan_enable(enable)
    local lanzone = fw:get_zone(pr.lanzone)

    if not lanzone then
        return false
    end

    lanzone:del_forwardings_by("src")

    if enable then
        lanzone:add_forwarding_to(pr.wanzone)
    end
end


function tor_on()
    forwarding_lan_wan_enable(false)
    redirect_to_tor_enable(true)
end
function tor_off()
    redirect_to_tor_enable(false)
end

function redirect_to_tor_enable(enable)
    local lanzone = fw:get_zone(pr.lanzone)
    if not lanzone then
        return false
    end

    del_redirect(pr.tor_tcp_redirect)
    del_redirect(pr.tor_dns_redirect)

    if enable then
        local options = {
            enabled = '1',
            target = 'DNAT',
            proto = 'tcp',
            src = pr.lanzone,
            dest = pr.wanzone,
            src_dip = '! 192.168.0.0/16',
            extra = ' -j REDIRECT --to-ports 9040',
            name = pr.tor_tcp_redirect
        }
        lanzone:add_redirect(options)

        local options = {
            enabled = '1',
            target = 'DNAT',
            proto = 'udp',
            src = pr.lanzone,
            dest = pr.wanzone,
            src_dip = '! 192.168.0.0/16',
            extra = ' --dport 53 -j REDIRECT --to-ports 9953',
            name = pr.tor_dns_redirect
        }
        lanzone:add_redirect(options)

    end
end

function del_redirect(rname)
	uci_r:delete_all("firewall", "redirect",
		function(s)
			return (s.name == rname)
		end)
end



function vpn_on()

end
function vpn_off()

end


s = m:section(TypedSection, "settings")
s.anonymous = true

    s:tab("tor", translate("Tor settings"))
    s:tab("vpn", translate("VPN settings"))


-- Tor options

o = s:taboption("tor", Flag, "tor_use_proxy", translate("Use proxy"))
o.optional = true

o = s:taboption("tor", Flag, "tor_limit_ports", translate("Use ports only"))
o.optional = true

o = s:taboption("tor", Flag, "tor_use_bridges", translate("Use bridges"))
o.optional = true



-- VPN options

o = s:taboption("vpn", Value, "vpn_server", translate("VPN server address"))
o.optional = true
o.datatype = "ipaddr"
o.placeholder = "0.0.0.0"

o = s:taboption("vpn", Value, "vpn_port", translate("VPN server UDP port"))
o.optional = true
o.datatype = "port"
o.placeholder = 8888

o = s:taboption("vpn", ListValue, "vpn_cipher", translate("Encryption cipher"), translate("Cipher used to encrypt the VPN tunnel"))
o.optional = true
o.default = "AES-256-CBC"
o:value("AES-256-CBC")
o:value("AES-192-CBC")
o:value("AES-128-CBC")
o:value("DES-CBC")
o:value("RC2-CBC")
o:value("DES-EDE-CBC")
o:value("DES-EDE3-CBC")
o:value("DESX-CBC")
o:value("BF-CBC")
o:value("RC2-40-CBC")
o:value("CAST5-CBC")
o:value("RC2-64-CBC")
o:value("SEED-CBC")

o = s:taboption("vpn", Flag, "vpn_complzo", translate("Use compression"), translate("Use LZO compression"))
o.optional = true
o.default = o.enabled


o = s:taboption("vpn", TextValue, "vpn_ca", translate("Certificate authority"))
o.optional = true
o.wrap    = "off"
o.rows    = 5
o.rmempty = false

function o.cfgvalue()
    return fs.readfile("/etc/openvpn/ca.crt") or ""
end

function o.write(self, section, value)
    if value then
        fs.writefile("/etc/openvpn/ca.crt", value:gsub("\r\n", "\n"))
    end
end


o = s:taboption("vpn", TextValue, "vpn_clientcrt", translate("Client certificate"))
o.optional = true
o.wrap    = "off"
o.rows    = 5
o.rmempty = false

function o.cfgvalue()
    return fs.readfile("/etc/openvpn/client.crt") or ""
end

function o.write(self, section, value)
    if value then
        fs.writefile("/etc/openvpn/client.crt", value:gsub("\r\n", "\n"))
    end
end

o = s:taboption("vpn", TextValue, "vpn_clientkey", translate("Client certificate key"))
o.optional = true
o.wrap    = "off"
o.rows    = 5
o.rmempty = false

function o.cfgvalue()
    return fs.readfile("/etc/openvpn/client.key") or ""
end

function o.write(self, section, value)
    if value then
        fs.writefile("/etc/openvpn/client.key", value:gsub("\r\n", "\n"))
    end
end


---
o = s:taboption("vpn", TextValue, "vpn_hmac", translate("HMAC authentication"),
    translate("Optional layer of HMAC authentication on top of the TLS control channel"..
            "to protect against DoS attacks"))
o.optional = true
o.wrap    = "off"
o.rows    = 5
o.rmempty = false

function o.cfgvalue()
    return fs.readfile("/etc/openvpn/hmac.auth") or ""
end

function o.write(self, section, value)
    if value then
        fs.writefile("/etc/openvpn/hmac.auth", value:gsub("\r\n", "\n"))
    end
end



return m
