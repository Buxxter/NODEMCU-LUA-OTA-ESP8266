function load_lib(fname)
    if file.open(fname .. ".lc") then
        file.close()
        dofile(fname .. ".lc")
    else
        dofile(fname .. ".lua")
    end
    collectgarbage()
end

function unrequire(m)
	package.loaded[m] = nil
    -- _G[m] = nil
    collectgarbage()
end



print ("nodeID is: " .. node.chipid())

local ota_lib = require("ota_lib")
ota_lib.print_settings()

if ota_lib.reboots_to_update then 
    ota_lib.set('reboots_to_update', ota_lib.reboots_to_update - 1)
end

if (ota_lib.host and ota_lib.host~="") then
    if (tonumber(ota_lib.update_check_s)>0) then
        local tmr_update = tmr.create()
        tmr_update:alarm (tonumber(ota_lib.update_check_s)*1000, tmr.ALARM_SEMI, function()
                local ota_lib = require("ota_lib")
                ota_lib.update()
                unrequire ('ota_lib')
                tmr_update:start()
            end)
    end
    if not ota_lib.need_update() then
        -- Remove if wifi configured in s.boot
        -- TODO: make good wifi connection script for this
        --
        -- wifi.setmode(wifi.STATION)
        -- wifi_config =   {   
        --                     ssid = s.ssid, 
        --                     pwd = s.pwd, 
        --                     auto = true, 
        --                     save = false,
        --                 }
        -- wifi.sta.config(wifi_config)
        -- wifi.sta.connect()
        local boot_file = ota_lib.boot
        unrequire ('ota_lib')
        print('Running ' .. boot_file)
        load_lib(boot_file)
    else
        -- feed_update_wdt()
        load_lib("ota_client")
    end
else
    load_lib("ota_server")
end