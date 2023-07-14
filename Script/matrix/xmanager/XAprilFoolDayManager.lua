--2023愚人节
XAprilFoolDayManagerCreator = function()
    local XAprilFoolDayManager = {}

    -- 标题时间
    local TITLE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleStartTime"))
    local TITLE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayTitleEndTime"))
    -- Q版模型时间
    local CUTE_START_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModeltartTime"))
    local CUTE_END_TIME = XTime.ParseToTimestamp(CS.XGame.ClientConfig:GetString("AprilFoolsDayCuteModelEndTime"))
    
    function XAprilFoolDayManager.IsInTitleTime()
        local curTime = os.time()
        return curTime >= TITLE_START_TIME and curTime < TITLE_END_TIME
    end

    function XAprilFoolDayManager.IsInCuteModelTime()
        local curTime = os.time()
        return curTime >= CUTE_START_TIME and curTime < CUTE_END_TIME
    end

    return XAprilFoolDayManager
end