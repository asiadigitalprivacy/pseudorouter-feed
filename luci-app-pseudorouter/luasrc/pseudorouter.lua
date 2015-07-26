
module("luci.pseudorouter", package.seeall)

radiodev = "radio0"

-- config wifi-iface
    -- option network "wificlient"
clientnetwork = 'wificlient'

    -- option network "lan"
apnetwork = 'lan'

lanzone = 'lan'
wanzone = 'wan'

tor_tcp_redirect = 'tor_tcp_redirect'
tor_dns_redirect = 'tor_dns_redirect'

--print("Content-type: text/plain\n\n")
--pr.tprint(net, 2)

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

