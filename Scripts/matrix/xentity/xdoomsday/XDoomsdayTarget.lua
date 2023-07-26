local TARGET_STATE = {
    UNFINISHED = 0, --未完成
    FINISHED = 1, --已完成
    EXPIRED = 2 --过期
}

local Default = {
    _Id = 0,
    _StartDay = 0, --开始天数
    _EndDay = 0, --结束天数（为0时不限期）
    _Value = 0, --进度(已完成数量)
    _MaxValue = 0, --进度(最大数量)
    _State = TARGET_STATE.UNFINISHED, --状态
    _IsExtra = false, --检查是否是关卡中额外接取的任务（不属于初始主任务/子任务）
    _Passed = false --是否达成目标
}

--末日生存玩法-关卡目标
local XDoomsdayTarget = XClass(XDataEntityBase, "XDoomsdayTarget")

function XDoomsdayTarget:Ctor(isExtra)
    self:Init(Default)
    self:SetProperty("_IsExtra", isExtra)
end

function XDoomsdayTarget:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_StartDay", data.AddedDay)
    self:SetProperty("_EndDay", data.LimitEndDay)
    self:SetProperty("_State", data.ConditionDb.State)
    self:SetProperty("_Value", data.ConditionDb.Value)
    self:SetProperty("_MaxValue", data.ConditionDb.MaxValue)
    self:SetProperty("_Passed", self._State == TARGET_STATE.FINISHED)
end

--需要展示的支线任务
function XDoomsdayTarget:IsExtraToShow()
    if not self:GetProperty("_IsExtra") then
        return false
    end
    return self:GetProperty("_State") == TARGET_STATE.UNFINISHED
end

return XDoomsdayTarget
