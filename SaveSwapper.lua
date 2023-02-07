local file = io.open("swapper.ini", "r")
local repalcevalue
local searchLine
if file then
    file:read("*line")
    searchLine = file:read("*line")
    searchvalue = string.gsub(searchLine, "%s", "")
    file:read("*line")
    repalcevalue = file:read("*line")
    repalcevalue = string.gsub(repalcevalue, "%s", "")
    file:close()
else
    searchvalue = inputQuery("Value Prompt", "Current XUID (decimal)", "")
    repalcevalue = inputQuery("Value Prompt", "Save XUID (decimal)", "")
    file = io.open("swapper.ini", "w")
    file:write("[AccountXUID]\n" .. searchvalue .. "\n[SaveXUID]\n" .. repalcevalue)
    file:close()
end

PROCESS_NAME = "ForzaHorizon5.exe"
local autoAttachTimer = nil
local autoAttachTimerInterval = 100
local autoAttachTimerTicks = 0
local autoAttachTimerTickMax = 5000

local function autoAttachTimer_tick(timer)
    if getProcessIDFromProcessName(PROCESS_NAME) ~= nil then
        -- Main script ends here
        timer.destroy()
        openProcess(PROCESS_NAME)
        -- Main script starts here
        local memscan = createMemScan()

        memscan.firstScan(
            soExactValue,
            vtQword,
            rtRounded,
            searchvalue,
            "",
            0,
            0xffffffffffffffff,
            "+W-X-C",
            fsmAligned,
            "8",
            false,
            false,
            false,
            false
        )
        memscan.waitTillDone()

        local foundlist = createFoundList(memscan)
        foundlist.initialize()

        if foundlist.Count > 0 then
            for i = 0, foundlist.Count - 1 do
                local address = foundlist.Address[i]
                writeQword(address, repalcevalue)
            end
            local confirm =
                messageDialog("Continue?, Make sure your in menu before pressing Yes", mtConfirmation, mbYesNo)
            if confirm == mrYes then
                memscan.firstScan(
                    soExactValue,
                    vtQword,
                    rtRounded,
                    repalcevalue,
                    "",
                    0,
                    0xffffffffffffffff,
                    "+W-X-C",
                    fsmAligned,
                    "8",
                    false,
                    false,
                    false,
                    false
                )
                memscan.waitTillDone()

                local newfoundlist = createFoundList(memscan)
                newfoundlist.initialize()

                for i = 0, newfoundlist.Count - 1 do
                    local address = newfoundlist.Address[i]
                    writeQword(address, searchvalue)
                end
                newfoundlist.destroy()
                messageDialog("Done", mtInformation, mbYes)
            end
        end

        foundlist.destroy()
        memscan.destroy()
    elseif autoAttachTimerTickMax > 0 and autoAttachTimerTicks >= autoAttachTimerTickMax then
        timer.destroy()
    end
    autoAttachTimerTicks = autoAttachTimerTicks + 1
end

autoAttachTimer = createTimer(MainForm)
autoAttachTimer.Interval = autoAttachTimerInterval
autoAttachTimer.OnTimer = autoAttachTimer_tick
