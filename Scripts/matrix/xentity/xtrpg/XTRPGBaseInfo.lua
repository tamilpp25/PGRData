local type = type

local XTRPGBaseInfo = XClass(nil, "XTRPGBaseInfo")

local Default = {
    __Level = 1, --探索等级
    __Exp = 0, --探索经验
    __Endurance = 0, --当前耐力
    __MaxEndurance = 0, --耐力上限
}

function XTRPGBaseInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__MaxEndurance = CS.XGame.Config:GetInt("TrpgMaxEndurance")
end

function XTRPGBaseInfo:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self.__Level = data.Level
    self.__Exp = data.Exp
    self.__Endurance = data.Endurance

    self:CheckLevelUpTips()
    self:InitRedPointLevel()
    XEventManager.DispatchEvent(XEventId.EVENT_TRPG_BASE_INFO_CHANGE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_BASE_INFO_CHANGE)
end

function XTRPGBaseInfo:UpdateEndurance(endurance)
    self.__Endurance = endurance
    XEventManager.DispatchEvent(XEventId.EVENT_TRPG_BASE_INFO_CHANGE)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_BASE_INFO_CHANGE)
end

function XTRPGBaseInfo:GetLevel()
    return self.__Level
end

function XTRPGBaseInfo:GetExp()
    return self.__Exp
end

function XTRPGBaseInfo:GetMaxExp()
    return XTRPGConfigs.GetMaxExp(self.__Level)
end

function XTRPGBaseInfo:GetEndurance()
    return self.__Endurance
end

function XTRPGBaseInfo:GetMaxEndurance()
    return self.__MaxEndurance
end

function XTRPGBaseInfo:GetMaxTalentPoint()
    return XTRPGConfigs.GetMaxTalentPoint(self.__Level)
end

function XTRPGBaseInfo:CheckLevelUpTips()
    local level = self:GetLevel()
    if not self.OldLevel then
        self.OldLevel = level
        return
    end
    if self.OldLevel ~= level then
        self.OldLevel = level
        local text = CS.XTextManager.GetText("TRPGLevelUpTips")
        XUiManager.TipMsgEnqueue(text)
    end
end

function XTRPGBaseInfo:InitRedPointLevel()
    if not self.RedPointLevel then
        local redPointLevel = XDataCenter.TRPGManager.GetExploreRedPointLevel()
        if redPointLevel then
            self.RedPointLevel = redPointLevel
        else
            local level = self:GetLevel()
            self.RedPointLevel = level
            XDataCenter.TRPGManager.SaveExploreRedPointLevel(level)
        end
    end
end

function XTRPGBaseInfo:GetRedPointLevel()
    return self.RedPointLevel
end

return XTRPGBaseInfo