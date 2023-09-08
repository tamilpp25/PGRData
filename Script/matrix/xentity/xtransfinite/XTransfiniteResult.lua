local XTransfiniteMedal = require("XEntity/XTransfinite/XTransfiniteMedal")

---@class XTransfiniteResult
local XTransfiniteResult = XClass(nil, "XTransfiniteResult")

function XTransfiniteResult:Ctor()
    self._WinAmount = 0
    self._ClearTime = 0
    self._IsCanGoOn = false
    self._IsNewRecord = false
    self._IsCompleteExtraCondition = false
    self._IsShowExtraCondition = false
    self._TextCondition = ""
    self._StageId = false
    self._StageGroupId = false
    self._IsWin = false
    self._CharacterResultList = false
    self._IsConfirm = false
    ---@type XTransfiniteMedal
    self._Medal = XTransfiniteMedal.New()
    self._RewardGoodList = false
    self._IsSettle = false
    self._StageGroupClearTime = 0
    self._IsSomeoneDead = false
end

function XTransfiniteResult:SetDataFromClient(data)
    self._StageGroupId = data.StageGroupId
    local stageGroup = self:GetStageGroup()
    self._WinAmount = stageGroup:GetStageAmountClear()
    local stage = stageGroup:GetStageByIndex(self._WinAmount)
    -- 一关都还没打， 取第一关
    if not stage then
        stage = stageGroup:GetStageByIndex(1)
    end
    self._StageId = stage:GetId()
    self._StageGroupClearTime = stageGroup:GetTotalClearTime()
end

function XTransfiniteResult:SetRewardGoodList(value)
    self._RewardGoodList = value
end

---@param stageGroup XTransfiniteStageGroup
function XTransfiniteResult:SetDataFromLastResult(stageGroup)
    local lastResult = stageGroup:GetLastResult()
    local currentStage = stageGroup:GetCurrentStage()
    if not currentStage then
        XLog.Error("[XTransfiniteResult] no current stage")
        return
    end
    local settleData = {
        IsWin = true,
        StageId = currentStage:GetId(),
        TransfiniteBattleResult = lastResult
    }
    self:SetDataFromServer(settleData)
end

function XTransfiniteResult:SetDataFromServer(settleData)
    self._IsWin = settleData.IsWin
    self._StageId = settleData.StageId
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroupByStageId(self._StageId)
    self._StageGroupId = stageGroup:GetId()
    local stage = stageGroup:GetStage(self._StageId)
    self._WinAmount = stageGroup:GetStageIndex(stage)
    if not self._IsWin then
        self._IsWin = self._IsWin - 1
    end

    --local rewardGoods = settleData.RewardGoodsList
    local result = settleData.TransfiniteBattleResult
    self._CharacterResultList = result.CharacterResultList
    local time = result.StageSpendTime
    self._ClearTime = time
    self._StageGroupClearTime = stageGroup:GetTotalClearTime() + self._ClearTime

    self._IsNewRecord = false

    if stage:IsExtraMission() then
        if stageGroup:IsIsland() then
            if self._WinAmount == XTransfiniteConfigs.IslandSpecialStage.FirstHideExtra then
                self._IsShowExtraCondition = false
            elseif self._WinAmount == XTransfiniteConfigs.IslandSpecialStage.SecondHideExtra then
                self._IsShowExtraCondition = false
            elseif self._WinAmount == XTransfiniteConfigs.IslandSpecialStage.ShowOtherExtra then
                self._IsShowExtraCondition = true
                self._IsCompleteExtraCondition = not stage:IsExtraMissionIncomplete(time)
                self._TextCondition = stage:GetExtraMissionText(true)
            end
        else
            self._IsShowExtraCondition = true
            self._IsCompleteExtraCondition = not stage:IsExtraMissionIncomplete(time)
            self._TextCondition = stage:GetExtraMissionText()
        end
    else
        self._IsShowExtraCondition = false
    end

    -- someone dead
    if self._CharacterResultList then
        local isSomeoneDead = false
        local team = stageGroup:GetTeam()
        for i = 1, #self._CharacterResultList do
            local character = self._CharacterResultList[i]
            if character.HpPercent <= 0 then
                local characterId = character.CharacterId
                local member = team:GetMemberByCharacterId(characterId)
                if member and member:IsValid() then
                    if member:GetHp() > 0 then
                        isSomeoneDead = true
                        break
                    end
                end
            end
        end
        self:SetSomeoneDead(isSomeoneDead)
    end
end

function XTransfiniteResult:GetWinAmount()
    return self._WinAmount or 0
end

function XTransfiniteResult:GetCondition()
    return self._TextCondition
end

function XTransfiniteResult:GetClearTime()
    return self._ClearTime
end

function XTransfiniteResult:GetStageGroupClearTime()
    return self._StageGroupClearTime
end

function XTransfiniteResult:IsCanGoOn()
    return self._IsCanGoOn
end

function XTransfiniteResult:IsNewRecord()
    return self._IsNewRecord
end

function XTransfiniteResult:IsCompleteExtraCondition()
    return self._IsCompleteExtraCondition
end

function XTransfiniteResult:IsShowExtraCondition()
    return self._IsShowExtraCondition
end

function XTransfiniteResult:GetStageId()
    return self._StageId
end

function XTransfiniteResult:GetStageGroupId()
    return self._StageGroupId
end

---@return XTransfiniteStageGroup
function XTransfiniteResult:GetStageGroup()
    return XDataCenter.TransfiniteManager.GetStageGroup(self._StageGroupId)
end

---@return XTransfiniteStage
function XTransfiniteResult:GetStage()
    return self:GetStageGroup():GetStage(self._StageId)
end

function XTransfiniteResult:GetStageGroupName()
    local stageGroup = self:GetStageGroup()
    return stageGroup:GetName()
end

function XTransfiniteResult:Confirm()
    self._IsConfirm = true
end

function XTransfiniteResult:IsConfirm()
    return self._IsConfirm
end

function XTransfiniteResult:GetStageId()
    return self._StageId
end

function XTransfiniteResult:GetCharacterData()
    return self._CharacterResultList
end

function XTransfiniteResult:GetMedal()
    self._Medal:SetTime(self._StageGroupClearTime)
    return self._Medal
end

function XTransfiniteResult:IsFinalStage()
    local stageGroup = self:GetStageGroup()
    local stage = stageGroup:GetStage(self._StageId)
    local isFinalStage = stageGroup:IsFinalStage(stage)
    return isFinalStage
end

function XTransfiniteResult:IsWin()
    return self._IsWin
end

function XTransfiniteResult:SetIsSettle(value)
    self._IsSettle = value
end

function XTransfiniteResult:IsSettle()
    return self._IsSettle
end

function XTransfiniteResult:GetRewardGoodList()
    return self._RewardGoodList
end

function XTransfiniteResult:IsNextStageLock()
    local stage = self:GetStage()
    local stageGroup = self:GetStageGroup()
    local nextStage = stageGroup:GetNextStage(stage)
    if not nextStage then
        return false
    end
    local isUnlock = nextStage:IsUnlockPreCheck(self:GetClearTime())
    return not isUnlock
end

function XTransfiniteResult:IsExtraMissionIncomplete()
    local stage = self:GetStage()
    local time = self:GetClearTime()
    return stage:IsExtraMissionIncomplete(time)
end

function XTransfiniteResult:IsSomeoneDead()
    return self._IsSomeoneDead
end

function XTransfiniteResult:SetSomeoneDead(value)
    self._IsSomeoneDead = value
end

return XTransfiniteResult
