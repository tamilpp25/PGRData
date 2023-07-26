local type = type
local pairs = pairs
local mathCeil = math.ceil
local CsXTextManagerGetText = CS.XTextManager.GetText

local Default = {
    _Day = 0, --天数
    _LendCount = 0, --借出次数
    _LendDuration = 0, --借出时长（分钟）
    _IsPause = false, --当天是否暂停结算
    _LendRewardValue = 0, --借用奖励数量
    _SetTimeRewardValue = 0, --设置时间奖励数量
}

local XStrongholdAssistantRecord = XClass(nil, "XStrongholdAssistantRecord")

function XStrongholdAssistantRecord:Ctor(day)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Day = day
end

function XStrongholdAssistantRecord:UpdateData(recordInfo)
    if XTool.IsTableEmpty(recordInfo) then return end

    self._LendCount = recordInfo.LendCount or self._LendCount
    self._LendDuration = recordInfo.SetTime and mathCeil(recordInfo.SetTime / 60) or self._LendDuration--(s)
    self._IsPause = recordInfo.IsStay and true or false
    self._LendRewardValue = recordInfo.LendRewardValue or self._LendRewardValue
    self._SetTimeRewardValue = recordInfo.SetTimeRewardValue or self._SetTimeRewardValue
end

function XStrongholdAssistantRecord:GetDay()
    return self._Day
end

function XStrongholdAssistantRecord:IsPause()
    return self._IsPause and true or false
end

function XStrongholdAssistantRecord:GetLendCount()
    return self._LendCount
end

function XStrongholdAssistantRecord:GetLendRewardItemInfo()
    local itemId = XStrongholdConfigs.GetCommonConfig("LendCharacterRewardItem")
    return itemId, mathCeil(self._LendRewardValue)
end

function XStrongholdAssistantRecord:GetLendRewardRecordString()
    local itemId, itemCount = self:GetLendRewardItemInfo()
    if itemCount == 0 then return "" end

    local itemName = XItemConfigs.GetItemNameById(itemId)
    return XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdSetAssistRecordLendCount", self._Day, self._LendCount, itemName, itemCount))
end

function XStrongholdAssistantRecord:GetLendDuration()
    return self._LendDuration
end

function XStrongholdAssistantRecord:GetDurationRewardItemInfo()
    local itemId = XStrongholdConfigs.GetCommonConfig("SetAssistCharacterRewardItem")
    return itemId, mathCeil(self._SetTimeRewardValue)
end

function XStrongholdAssistantRecord:GetDurationRewardRecordString()
    local itemId, itemCount = self:GetDurationRewardItemInfo()
    if itemCount == 0 then return "" end

    local itemName = XItemConfigs.GetItemNameById(itemId)
    return XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdSetAssistRecordDuration", self._Day, self._LendDuration, itemName, itemCount))
end

function XStrongholdAssistantRecord:GetDelayRecordString()
    return XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("StrongholdSetAssistRecordDelay", self._Day))
end

return XStrongholdAssistantRecord