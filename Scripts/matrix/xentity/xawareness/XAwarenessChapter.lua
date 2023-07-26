local XAwarenessChapter = XClass(nil, "XAwarenessChapter")

local CHARACTERTYPE_ALL = 0
local SKILLTYPE_BITS = 1000

function XAwarenessChapter:Ctor(id)
    self.Id = id
    self.CharacterId = nil -- 驻守角色
    self.Rewarded = false -- 已领奖
    self.IsPassByServer = nil -- 服务器已通关标记
    self.FightCount = 0
end

function XAwarenessChapter:GetCfg()
    return XFubenAwarenessConfigs.GetAllConfigs(XFubenAwarenessConfigs.TableKey.AwarenessChapter)[self.Id]
end
function XAwarenessChapter:GetId() return self.Id end
function XAwarenessChapter:GetName() return self:GetCfg().Name end
function XAwarenessChapter:GetDesc() end
function XAwarenessChapter:GetOrderId() end
function XAwarenessChapter:GetIcon() return self:GetCfg().Cover end
function XAwarenessChapter:GetSelectCharCondition() return self:GetCfg().SelectCharCondition end
function XAwarenessChapter:GetTeamInfoId() return self:GetCfg().TeamInfoId end
function XAwarenessChapter:GetRewardId() return self:GetCfg().RewardId end
function XAwarenessChapter:GetStageId() return self:GetCfg().StageId end
function XAwarenessChapter:GetBaseStageId() return self:GetCfg().BaseStage end

function XAwarenessChapter:IsCharConditionMatch(characterId)
    local isMatch = true
    local conditions = self:GetSelectCharCondition()
    for _, conditionId in ipairs(conditions) do
        if not (XConditionManager.CheckCondition(conditionId, characterId)) then
            isMatch = false
            break
        end
    end
    return isMatch
end

function XAwarenessChapter:GetBuffDesc()
    local id = self:GetCfg().FightEventId
    return XRoomSingleManager.GetEvenDesc(id)
end

function XAwarenessChapter:GetChapterOrder()
    local list = XDataCenter.FubenAwarenessManager.GetChapterIdList()
    for k, id in pairs(list) do
        if self:GetId() == id then
            return k
        end
    end
end

-- server api
function XAwarenessChapter:SetFightCount(count)
    count = count or 0
    self.FightCount = count
end

function XAwarenessChapter:GetFightCount()
    return self.FightCount
end

function XAwarenessChapter:GetCharacterBodyIcon()
    return XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharacterId)
end

function XAwarenessChapter:IsRewarded()
    return self.Rewarded
end

function XAwarenessChapter:IsRed()
    if self:CanAssign() and not self:IsOccupy() then
        for k, char in pairs(XDataCenter.CharacterManager.GetOwnCharacterList()) do
            local isPassCond = self:IsCharConditionMatch(char.Id)
            local isOc = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(char.Id)
            if isPassCond and not isOc then
                return true
            end
        end
    end

    return false
end

function XAwarenessChapter:CanReward()
    return (self:IsPass() and not self:IsRewarded())
end

function XAwarenessChapter:IsUnlock()
   return true
end

function XAwarenessChapter:CanAssign()
    return self:IsPass()
end

-- server api
function XAwarenessChapter:SetRewarded(state)
    self.Rewarded = state
end

function XAwarenessChapter:GetPassNum()
    
end

function XAwarenessChapter:SetIsPassByServer(value)
    self.IsPassByServer = value
end

function XAwarenessChapter:IsPass()
    if self.IsPassByServer then
        return true
    end
    
    return self:GetFightCount() >= 1
end

function XAwarenessChapter:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XAwarenessChapter:IsOccupy()
    return (self.CharacterId and self.CharacterId ~= 0)
end

function XAwarenessChapter:GetCharacterId()
    return self.CharacterId
end

function XAwarenessChapter:GetOccupyCharacterIcon()
    return XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(self:GetCharacterId())
end

function XAwarenessChapter:GetOccupyCharSmallHeadIcon()
    return  XDataCenter.CharacterManager.GetCharSmallHeadIcon(self:GetCharacterId())
end

function XAwarenessChapter:GetOccupyCharacterName()
    return XCharacterConfigs.GetCharacterFullNameStr(self:GetCharacterId())
end

return XAwarenessChapter