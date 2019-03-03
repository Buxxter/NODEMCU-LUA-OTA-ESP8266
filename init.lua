function run()
    print("Starting...")
    if file.open("ota_init.lc") then
        file.close()
        dofile("ota_init.lc")
    else
        dofile("ota_init.lua")
    end
    run = nil
    collectgarbage()
end

debug = function (...)
    return
end

if file.open("debug") then
    print("Debug delay for 3s...")
    debug = function (...)
        print(...)
    end

    tmr.create():alarm(3000, tmr.ALARM_SINGLE, run)
else
    run()
end