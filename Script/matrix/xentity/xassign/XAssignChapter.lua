local XAssignChapter = XClass(nil, "XAssignChapter")

local CHARACTERTYPE_ALL = 0
local SKILLTYPE_BITS = 1000

function XAssignChapter:Ctor(id)
    self.Id = id
    self.CharacterId = nil -- 驻守角色
    self.Rewarded = false -- 已领奖
    self.IsPassByServer = nil -- 服务器已通关标记
end
function XAssignChapter:GetCfg()
    return XFubenAssignConfigs.GetChapterTemplateById(self.Id)
end
function XAssignChapter:GetId() return self.Id end
function XAssignChapter:GetName() return self:GetCfg().ChapterName end
function XAssignChapter:GetDesc() return self:GetCfg().ChapterEn end
function XAssignChapter:GetOrderId() return self:GetCfg().OrderId end
function XAssignChapter:GetIcon() return self:GetCfg().Cover end
function XAssignChapter:GetSkillPlusId() return self:GetCfg().SkillPlusId end
function XAssignChapter:GetSkillIcon() return self:GetCfg().SkillIcon end
function XAssignChapter:GetAssignCondition() return self:GetCfg().AssignCondition end
function XAssignChapter:GetSelectCharCondition() return self:GetCfg().SelectCharCondition end
function XAssignChapter:GetRewardId() return self:GetCfg().RewardId end
function XAssignChapter:GetGroupId() return self:GetCfg().GroupId end

-- 获得所有加成效果的key
function XAssignChapter:GetBuffKeys()
    if not self.BuffKeys then
        self.BuffKeys = {}
        local buffConfigId = self:GetSkillPlusId()
        if buffConfigId and buffConfigId ~= 0 then
            local plusConfig = XMVCA.XCharacter:GetSkillTypePlusTemplate(buffConfigId)
            if plusConfig then
                local key

                local isAllMember = (#plusConfig.CharacterType == #XMVCA.XCharacter:GetAllCharacterCareerIds())
                if isAllMember then
                    local characterType = CHARACTERTYPE_ALL
                    for _, skillType in ipairs(plusConfig.SkillType) do
                        key = characterType * SKILLTYPE_BITS + skillType
                        table.insert(self.BuffKeys, key)
                    end
                else
                    for _, characterType in ipairs(plusConfig.CharacterType) do
                        for _, skillType in ipairs(plusConfig.SkillType) do
                            key = characterType * SKILLTYPE_BITS + skillType
                            table.insert(self.BuffKeys, key)
                        end
                    end
                end
            end
        end
        self.BuffKeys = XDataCenter.FubenAssignManager.SortKeys(self.BuffKeys)
    end
    return self.BuffKeys
end

function XAssignChapter:GetBuffDescList()
    return XDataCenter.FubenAssignManager.GetBuffDescListByKeys(self:GetBuffKeys())
end

function XAssignChapter:IsCharConditionMatch(characterId)
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

function XAssignChapter:GetProgressStr()
    local groupNum = #self:GetGroupId()
    return math.floor((self:GetPassNum() / groupNum) * 100) .. "%"
end

function XAssignChapter:GetCharacterBodyIcon()
    return XMVCA.XCharacter:GetCharHalfBodyImage(self.CharacterId)
end

function XAssignChapter:IsRewarded()
    return self.Rewarded
end

function XAssignChapter:IsRed()
    if self:CanAssign() and not self:IsOccupy() then
        for k, char in pairs(XMVCA.XCharacter:GetOwnCharacterList()) do
            local isPassCond = self:IsCharConditionMatch(char.Id)
            local isOc = XDataCenter.FubenAssignManager.CheckCharacterInOccupy(char.Id)
            if isPassCond and not isOc then
                return true
            end
        end
    end

    return false
end

function XAssignChapter:CanReward()
    return (self:IsPass() and not self:IsRewarded())
end

function XAssignChapter:IsUnlock()
    for _, groupId in ipairs(self:GetGroupId()) do
        local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(groupId)
        if groupData and groupData:IsUnlock() then
            return true
        end
    end
    return false
end

function XAssignChapter:CanAssign()
    return self:IsPass() and self:IsMatchAssignCondition()
end

-- server api
function XAssignChapter:SetRewarded(state)
    self.Rewarded = state
end

function XAssignChapter:GetPassNum()
    local passNum = 0
    for _, groupId in ipairs(self:GetGroupId()) do
        local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(groupId)
        if groupData and groupData:IsPass() then
            passNum = passNum + 1
        end
    end
    return passNum
end

function XAssignChapter:SetIsPassByServer(value)
    self.IsPassByServer = value
end

function XAssignChapter:IsPass()
    if self.IsPassByServer then
        return true
    end
    local groupNum = #self:GetGroupId()
    return (self:GetPassNum() >= groupNum)
end

function XAssignChapter:IsMatchAssignCondition()
    for _, conditionId in ipairs(self:GetAssignCondition()) do
        if not (XConditionManager.CheckCondition(conditionId)) then
            return false
        end
    end
    return true
end

function XAssignChapter:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XAssignChapter:IsOccupy()
    return (self.CharacterId and self.CharacterId ~= 0)
end

function XAssignChapter:GetCharacterId()
    return self.CharacterId
end

function XAssignChapter:GetOccupyCharacterIcon()
    return XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(self:GetCharacterId())
end

function XAssignChapter:GetOccupyCharSmallHeadIcon()
    return  XMVCA.XCharacter:GetCharSmallHeadIcon(self:GetCharacterId())
end


function XAssignChapter:GetOccupyCharacterName()
    return XMVCA.XCharacter:GetCharacterFullNameStr(self:GetCharacterId())
end

return XAssignChapter