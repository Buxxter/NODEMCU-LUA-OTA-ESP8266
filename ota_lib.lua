local module = {ssid="", pwd="", host="", domain="", path="", err="", boot="", update_check_s=0, debug="0"}

function module.LoadX()
    if (file.open("s.txt","r")) then
        local sF = file.read()
        -- print("Setting: ")
        file.close()
        for k, v in string.gmatch(sF, "([%w_.]+)=([%S ]+)") do    
            module[k] = v
            -- print(k .. ": " .. v)
        end
        if module.debug == "1" and not file.open("debug") then
            file.open("debug", "w")
            file.close()
        elseif module.debug ~= "1" then
            file.remove("debug")
        end
    end
end

function module.print_settings()
    print("OTA Setting: ")
    for k,v in pairs(module) do
        if type(v) ~= 'table' and type(v) ~= 'function' then
            print(k .. ': ' .. v)
        end
    end
end

function module.SaveXY(sErr)
    if (sErr) then
        module.err = sErr
    end
    if module.reboots_to_update < 0 then module.reboots_to_update = 10 end
    file.remove("s.txt")
    file.open("s.txt","w+")
    for k, v in pairs(module) do
        if type(v) ~= 'table' and type(v) ~= 'function' then
            file.writeline(k .. "=" .. v)
        end
    end                
    file.close()
    collectgarbage()
end

function module.set(key, val)
    module[key] = val
    module.SaveXY()
end

local function feed_update_wdt()
    module.set('reboots_to_update', 10)
end

function module.update()
    uart.write(0,"checking for update... ")
    if not wifi.sta.getip() then
        print("WiFi not connected")
        return
    end
    local conn=net.createConnection(net.TCP, 0)
    conn:on("connection",function(conn, payload)
        conn:send("GET /"..module.path.."/node.php?id="..node.chipid().."&update"..
                    " HTTP/1.1\r\n".. 
                    "Host: "..module.domain.."\r\n"..
                    "Connection: close\r\n"..
                    "Accept: */*\r\n"..
                    "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                    "\r\n\r\n") 
    end)

    conn:on("receive", function(conn, payload)
        if string.find(payload, "UPDATE")~=nil then 
            module.set('boot', nil)
            feed_update_wdt()
            node.restart()
        else
            print('no new updates | ' .. node.heap())
        end
        
        -- conn:close()
        conn = nil

    end)
    conn:connect(80,module.host)
end

function module.need_update()
    return not (module.boot and module.boot~="" and module.boot~="init_ota" and (module.reboots_to_update == nil or module.reboots_to_update > 0))
end

function module.wifi_connect()
    if wifi.sta.getip() then
        print("WiFi already connected")
        return
    end
    wifi.setmode(wifi.STATION)
    local wifi_config = {   
                            ssid = module.ssid, 
                            pwd = module.pwd, 
                            auto = true, 
                            save = false,
                        }
    wifi.sta.config(wifi_config)
    wifi.sta.connect()
end

module.LoadX()

return module