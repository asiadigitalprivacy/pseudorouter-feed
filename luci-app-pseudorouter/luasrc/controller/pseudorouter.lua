module("luci.controller.pseudorouter", package.seeall)

local wl = require "luci.model.cbi.pseudorouter.wifi_lib"

function wifi_status(devs)
    wl.wifi_status(devs)
end

function wifi_delete(network)
    wl.wifi_delete(network)
end

function ap_status(devs)
    wl.ap_status(devs)
end

function ap_delete(network)
    wl.ap_delete(network)
end

function index()
    if not nixio.fs.access("/etc/config/pseudorouter") then
        return
    end

    if not nixio.fs.access("/etc/config/pseudorouter_expert") then
	    entry({"admin", "overview"}, template("admin_status/index"), _("Overview"), 1)
        entry({"admin"}, alias("admin", "overview"), _("PseudoRouter"), 1)

        local disp = require "luci.dispatcher"
        local treecache  = disp.context.treecache
        treecache['admin.status'].title = nil
        treecache['admin.system'].title = nil
        treecache['admin.network'].title = nil

        entry({"admin", "admin"}, alias("admin", "system", "admin"), _("Admin"), 85)
	    entry({"admin", "reboot"}, alias("admin", "system", "reboot"), _("Reboot"), 85)
    end

	entry({"admin"}, alias("admin", "status", "overview"), _("Status"), 1).index = true

    entry({"admin", "wifi"}, template("pseudorouter/wifi_overview"), _("Wifi client"), 10).leaf = true
        entry({"admin", "wifi_scan"}, template("pseudorouter/wifi_scan"), nil).leaf = true
        entry({"admin", "wifi_add"}, cbi("pseudorouter/wifi_add"), nil).leaf = true
        entry({"admin", "wifi_hidden"}, cbi("pseudorouter/wifi_hidden"), nil).leaf = true
        entry({"admin", "wifi_settings"}, cbi("pseudorouter/wifi_settings"), nil).leaf = true
        entry({"admin", "wifi_status"}, call("wifi_status"), nil).leaf = true
        entry({"admin", "wifi_delete"}, call("wifi_delete"), nil).leaf = true

    entry({"admin", "ap"}, template("pseudorouter/ap_overview"), _("Access Point"), 11).leaf = true
        entry({"admin", "ap_setup"}, cbi("pseudorouter/ap_setup"), nil).leaf = true
        entry({"admin", "ap_settings"}, cbi("pseudorouter/ap_settings"), nil).leaf = true
        entry({"admin", "ap_ip_settings"}, cbi("pseudorouter/ap_ip_settings"), nil).leaf = true
        entry({"admin", "ap_status"}, call("ap_status"), nil).leaf = true
        entry({"admin", "ap_delete"}, call("ap_delete"), nil).leaf = true

	entry({"admin", "mode"}, cbi("pseudorouter/mode"), _("Mode"), 12).leaf = true

end
