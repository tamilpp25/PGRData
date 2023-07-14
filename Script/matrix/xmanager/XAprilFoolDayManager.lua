--2022愚人节
XAprilFoolDayManagerCreator = function()
    local XAprilFoolDayManager = {}

    local START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayStartTime"))
    local END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayEndTime"))

    function XAprilFoolDayManager.IsInTime()
        local curTime = os.time()
        return curTime >= START_TIME and curTime < END_TIME
    end

    return XAprilFoolDayManager
end