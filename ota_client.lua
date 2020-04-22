local ota_lib = require('ota_lib')

function write(str)
    uart.write(0, str)
end

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
        end
        return t
end

function update_state()
    -- TODO: update file only on 200 OK on:disconnect
    write("Sending updated state...")
    conn=net.createConnection(net.TCP, 0)
    conn:on("connection",function(conn, payload)
    conn:send("GET /"..ota_lib.path.."/node.php?id="..node.chipid().."&update=1"..
                " HTTP/1.1\r\n".. 
                "Host: "..ota_lib.domain.."\r\n"..
                "Connection: close\r\n"..
                "Accept: */*\r\n"..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)"..
                "\r\n\r\n") 
            end)

    conn:on("receive", function(conn, payload)
        print("Done")
        ota_lib.SaveXY("No error")
        print("All files saved\nBootfile: " .. ota_lib.boot .. "\nReboot")
        collectgarbage()
        node.restart()
    end)
    conn:connect(80,ota_lib.host)
end

function dwn()
    -- body
    files_counter = files_counter + 1
    if data[files_counter] == nil then
        bootfile = string.gsub(data[1], '\.lua$', '')
        ota_lib.boot = bootfile --..".lc"
        tmr_get_file:unregister()
        update_state()
        return
    end

    filename = data[files_counter]
    write("Filename: " .. filename .. "...")
    
    file.remove(filename)
    file.remove(filename:gsub('\.lua$','\.lc'))
    file.open(filename, "w+")

    payloadFound = false
    
    -- TODO: Will change in upcoming releases:
    conn = net.createConnection(net.TCP) -- <= from
    -- conn = net.createConnection(net.TCP) -- <= to
    -- See https://nodemcu.readthedocs.io/en/master/en/modules/net/#netcreateconnection
    

    conn:on("receive", function(conn, payload)

        if (payloadFound == true) then
            file.write(payload)
            file.flush()
        else
            if (string.find(payload, "\r\n\r\n") ~= nil) then
                file.write(string.sub(payload, string.find(payload, "\r\n\r\n") + 4))
                file.flush()
                payloadFound = true
            end
        end

        payload = nil
        collectgarbage()
    end)

    conn:on("disconnection", function(conn) 
        conn = nil
        print("Done")
        file.close()
        -- if (string.sub(filename, -4) == ".lua") then
        --     node.compile(filename)
        -- end
        filename = nil
        tmr_get_file:start()
        collectgarbage()
        return
    end)
    
    conn:on("connection", function(conn)
        conn:send("GET /" .. ota_lib.path .. "/uploads/" .. node.chipid() .. "/" .. filename .. " HTTP/1.0\r\n" ..
                "Host: " .. ota_lib.host .. "\r\n" ..
                "Connection: close\r\n" ..
                "Accept-Charset: utf-8\r\n" ..
                "Accept-Encoding: \r\n" ..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n" ..
                "Accept: */*\r\n\r\n")
    end)
    
    conn:connect(80, ota_lib.host)

end

function FileList(sck, c)
    write("Check for update manifest...")
    
    local nStart = c:find("{start--")
    local nEnd = c:find("--end}")
    
    if nStart == nil or nEnd == nil then
        print("Missing markers")
        return
    end
    c = c:sub(nStart+9, nEnd-1)
    
    data = mysplit(c, "\n") -- fill the field with filenames
    
    filename = nil
    file_counter = 0
    if #data ~= 0 then
        print("Got filelist:")
        for key, val in pairs(data) do  -- Table iteration.
            print(key, val)
        end
        tmr_get_file = tmr.create()
        tmr_get_file:alarm(1000, tmr.ALARM_SEMI, dwn)
    else
        print("nothing to update")
        node.restart()
        return
    end

    collectgarbage()
end

print("fetch lua..")

data = {}
filename = nil
files_counter = 0

ota_lib.wifi_connect()

iFail = 12 -- trying to connect to AP in 60sec, if not then reboot
tmr_waif_for_connect = tmr.create()
tmr_waif_for_connect:alarm(5000, tmr.ALARM_AUTO, function()
  iFail = iFail - 1
  print(iFail)
  if (iFail == 0) then
    ota_lib.SaveXY("could not access " .. ota_lib.ssid)
    node.restart()
  end

  if wifi.sta.getip() == nil then
    print(ota_lib.ssid.. ": " .. iFail)
  else
    print("ip: " .. wifi.sta.getip())
    tmr_waif_for_connect:unregister()
    -- get list of files
    
    sk = net.createConnection()
    
    sk:on("connection",function(conn, payload)
                sk:send("GET /" .. ota_lib.path .. "/node.php?id=" .. node.chipid() .. "&list" ..
                " HTTP/1.1\r\n".. 
                "Host: ".. ota_lib.domain .. "\r\n" ..
                "Connection: close\r\n"..
                "Accept: */*\r\n" ..
                "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)" ..
                "\r\n\r\n")
            end)
    sk:on("receive", FileList)

    sk:on("reconnection", function (conn, err_code)
        print("Error (" .. err_code .. ") connecting " .. ota_lib.host)
        iFail = iFail - 1
        if (iFail == 0) then
            ota_lib.SaveXY("connection error (code " .. err_code .. ")")
            node.restart()
          end
        return
    end)

    -- TODO
    -- Add sk:on("disconnection") and sk:on("reconnection")
    -- to catch connection errors

    iFail = 12
    --sGet = "GET /".. s.path .. " HTTP/1.1\r\nHost: " .. s.domain .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    sk:connect(80, ota_lib.host)
    
  end
  collectgarbage()
 
end)

print(collectgarbage("count") .. " kB used")
