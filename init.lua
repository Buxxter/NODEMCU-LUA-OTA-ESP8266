if file.open("debug") then
    print("Debug delay for 3s...")
    tmr.delay(3000000)
    print("finished")
end
if file.open("init_ota.lc") then
    file.close()
    dofile("init_ota.lc")
else
    dofile("init_ota.lua")
end
