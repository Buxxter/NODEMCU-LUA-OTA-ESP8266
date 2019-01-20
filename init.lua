function run()
    print("Starting...")
    if file.open("init_ota.lc") then
        file.close()
        dofile("init_ota.lc")
    else
        dofile("init_ota.lua")
    end
end

if file.open("debug") then
    print("Debug delay for 3s...")
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, run)
else
    run()
end