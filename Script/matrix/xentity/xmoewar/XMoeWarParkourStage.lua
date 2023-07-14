

local Default = {
    Id = 0,
    TimeId  = 0,
    MarkId  = 0,
}

local TIME_FORMAT = "MM/dd"

--============================== 
---@desc 跑酷小游戏关卡类
--==============================
local XMoeWarParkourStage = XClass(nil, "XMoeWarParkourStage")

function XMoeWarParkourStage:Ctor(stageCfg)
    for key, value in pairs(Default) do
        self[key] = stageCfg[key] or value
    end
    self.Cfg = XDataCenter.FubenManager.GetStageCfg(self.Id)
    self.AllTimeHigh = 0
end 

--==============================
 ---@desc 获取历史最高分
 ---@return number
--==============================
function XMoeWarParkourStage:GetAllTimeHigh()
    return self.AllTimeHigh
end 

function XMoeWarParkourStage:RefreshAllTimeHigh(score)
    score = XTool.IsNumberValid(score) and score or 0
    if self.AllTimeHigh >= score then
        return
    end
    self.AllTimeHigh = score
end

--==============================
 ---@desc 关卡背景图
 ---@return string
--==============================
function XMoeWarParkourStage:GetBackground()
    return self.Cfg.Icon
end 

--==============================
 ---@desc 关卡名
 ---@return string
--==============================
function XMoeWarParkourStage:GetName()
    return self.Cfg.Name
end

--==============================
---@desc 关卡描述
---@return string
--==============================
function XMoeWarParkourStage:GetDesc()
    return self.Cfg.Description
end

--==============================
 ---@desc 获取关卡状态
 ---@return @XMoeWarConfig.ParkourGameState
--==============================
function XMoeWarParkourStage:GetState()
    local isEnd = self:IsOverTime()
    if isEnd then
        return XMoeWarConfig.ParkourGameState.Over
    end
    local isUnlock = self:IsUnLock()
    return isUnlock and XMoeWarConfig.ParkourGameState.Opening or XMoeWarConfig.ParkourGameState.Unopened
end

--==============================
---@desc 获取关卡Id
---@return number
--==============================
function XMoeWarParkourStage:GetId()
    return self.Id
end

--==============================
 ---@desc 是否为教学关
 ---@return boolean
--==============================
function XMoeWarParkourStage:IsTeachStage()
    return self.Id == XDataCenter.MoeWarManager.GetParkourTeachStageId()
end

--region   ------------------时间相关 start-------------------

--==============================
---@desc 关卡开始时间
---@return number
--==============================
function XMoeWarParkourStage:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.TimeId)
end

--==============================
---@desc 关卡开启~结束时间 例如：03/04-04/03
---@return string
--==============================
function XMoeWarParkourStage:GetDuringTime()
    local timeOfStr = XTime.TimestampToGameDateTimeString(self:GetStartTime(), TIME_FORMAT)
    local timeOfEnd = XTime.TimestampToGameDateTimeString(self:GetEndTime(), TIME_FORMAT)
    return string.format("%s-%s", timeOfStr, timeOfEnd)
end

--==============================
---@desc 关卡结束时间
---@return number
--==============================
function XMoeWarParkourStage:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.TimeId)
end


--==============================
---@desc 是否已结束
---@return boolean
--==============================
function XMoeWarParkourStage:IsOverTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = self:GetEndTime()
    return timeOfNow > timeOfEnd
end

--==============================
---@desc 关卡是否解锁
---@return boolean
--==============================
function XMoeWarParkourStage:IsUnLock()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = self:GetEndTime()
    local timeOfBgn = self:GetStartTime()
    return timeOfNow >= timeOfBgn and timeOfNow <= timeOfEnd
end

--==============================
---@desc 获取关卡开启剩余时间
---@return string
--==============================
function XMoeWarParkourStage:GetOpenTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfBgn = self:GetStartTime()
    return XUiHelper.GetTime(timeOfBgn - timeOfNow, XUiHelper.TimeFormatType.MOE_WAR)
end

--endregion------------------时间相关 finish------------------



return XMoeWarParkourStage
