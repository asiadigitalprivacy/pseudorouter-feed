module("luci.model.cbi.pseudorouter.wifi_lib", package.seeall)

local ntm = require "luci.model.network".init()
local utl = require "luci.util"


function get_status_by_interface(interface)
    local s = utl.ubus("network.interface.%s" % interface, "status", {})
    return s
end

function get_proto(proto)
    return proto == 'dhcp' and "DHCP" or proto == 'static' and "Static" or proto
end

function wifi_status(devs)
	local status    = require "luci.tools.status"
	local rv   = { }

    if not devs then
	    luci.http.status(404, "No such device")
        return
    end

	local dev
	for dev in devs:gmatch("[%w%.%-]+") do
		local ds = status.wifi_network(dev)

        local net = ntm:get_wifinet(dev)
	    if net then
            local s = get_status_by_interface(net.iwdata.network)
            if s then
    			for _, a in pairs(ds.assoclist) do
                    a.proto   = get_proto(s['proto'])
                    a.ipaddr  = s["ipv4-address"][1]["address"]
                    a.netmask = "/%s" % s["ipv4-address"][1]["mask"]
                    a.gwaddr  = s["route"][1]["nexthop"]
                    a.dns     = s["dns-server"][1]
                end
            end
        end

		rv[#rv+1] = ds
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function ap_status(devs)
	local status    = require "luci.tools.status"
	local rv   = { }

    if not devs then
	    luci.http.status(404, "No such device")
        return
    end

	local dev
	for dev in devs:gmatch("[%w%.%-]+") do
		local ds = status.wifi_network(dev)

        local net = ntm:get_wifinet(dev)
	    if net then
            local s = get_status_by_interface(net.iwdata.network)
            if s then
                local a = ds
                a.proto   = get_proto(s['proto'])
                a.ipaddr  = s["ipv4-address"][1]["address"]
                a.netmask = "/%s" % s["ipv4-address"][1]["mask"]
                a.gwaddr  = a.ipaddr
                a.dns     = s["dns-server"][1]
            end
        end

		rv[#rv+1] = ds
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end


function wifi_delete(network)
	local wnet = ntm:get_wifinet(network)
	if wnet then
		local dev = wnet:get_device()
		local nets = wnet:get_networks()
		if dev then
			ntm:del_wifinet(network)
			ntm:commit("wireless")
			local _, net
			for _, net in ipairs(nets) do
				if net:is_empty() then
					ntm:del_network(net:name())
					ntm:commit("network")
				end
			end
			luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
		end
	end

	luci.http.redirect(luci.dispatcher.build_url("admin/wifi"))
end

function ap_delete(network)
	local wnet = ntm:get_wifinet(network)
	if wnet then
		local dev = wnet:get_device()
		if dev then
			ntm:del_wifinet(network)
			ntm:commit("wireless")
			luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
		end
	end

	luci.http.redirect(luci.dispatcher.build_url("admin/ap"))
end

