local XBigWorldCharacterUiEffectInfo = require("XModule/XBigWorldCharacter/Data/XBigWorldCharacterUiEffectInfo")

local XBigWorldCharacter

---@class XBigWorldCharacterModel : XModel
---@field _CharDict table<number, XBigWorldCharacter>
local XBigWorldCharacterModel = XClass(XModel, "XBigWorldCharacterModel")

local pairs = pairs

local TableCharacter = {
    BigWorldCharacter = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCharacterUiEffect = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
}

local TableFashion = {
    BigWorldFashion = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldCharacterModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Character", TableCharacter)
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Fashion", TableFashion)

    self._TrialCharacterIds = {}
    self._TrialCharacterMap = {}
    self._IsTrialCoverTeam = false

    self._UnlockRoleDict = {}
    self._AllRoleIds = false
    self._CurrentTeamId = 0
    
    self._CharDict = {}

    ---@type table<number, table<string, table<string, XBigWorldCharacterUiEffectInfo>>>
    self._CharacterUiEffectMap = false
end

function XBigWorldCharacterModel:ClearPrivate()
end

function XBigWorldCharacterModel:ResetAll()
    self._AllRoleIds = false
    self._UnlockRoleDict = {}
end

function XBigWorldCharacterModel:GetCurrentTeamId()
    return self._CurrentTeamId
end

function XBigWorldCharacterModel:SetCurrentTeamId(teamId)
    self._CurrentTeamId = teamId or 0
end

--- 获取Dlc角色配置
---@param characterId number
---@return XTableBigWorldCharacter
--------------------------
function XBigWorldCharacterModel:GetDlcCharacterTemplate(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableCharacter.BigWorldCharacter, characterId)
end

function XBigWorldCharacterModel:IsCommandant(characterId)
    local t = self:GetDlcCharacterTemplate(characterId)
    return t and t.IsCommandant or false
end

--- 获取全部角色(不包含指挥官)
---@return number[]
--------------------------
function XBigWorldCharacterModel:GetAllRoleIds()
    if self._AllRoleIds then
        return self._AllRoleIds
    end

    local list = {}
    ---@type table<number, XTableBigWorldCharacter>
    local templates = self._ConfigUtil:GetByTableKey(TableCharacter.BigWorldCharacter)
    for id, _ in pairs(templates) do
        if not self:IsCommandant(id) then
            list[#list + 1] = id
        end
    end
    self._AllRoleIds = list
    return list
end

function XBigWorldCharacterModel:IsRoleUnlock(characterId)
    if self._UnlockRoleDict[characterId] then
        return true
    end
    local t = self:GetDlcCharacterTemplate(characterId)
    local conditionId = t.Condition
    if not XTool.IsNumberValid(conditionId) then
        self._UnlockRoleDict[characterId] = true
        return true
    end
    local ret, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
    if ret then
        self._UnlockRoleDict[characterId] = true
        return true
    end

    return false
end

--- 获取Dlc时装配置
---@param fashionId number
---@return XTableBigWorldFashion
--------------------------
function XBigWorldCharacterModel:GetDlcFashionTemplate(fashionId, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableFashion.BigWorldFashion, fashionId, noTips)
end

function XBigWorldCharacterModel:GetFashionId(characterId)
    local t = self:GetDlcCharacterTemplate(characterId)
    if not t then
        return 0
    end
    if self:IsCommandant(characterId) then
        return XMVCA.XBigWorldCommanderDIY:GetCurrentFashionId()
    end
    --空花单独设置的涂装
    local char = self:GetDlcCharacter(characterId)
    local fashionId = char:GetFashionId()
    if fashionId and fashionId > 0 then
        return fashionId
    end
    ----角色未拥有
    --local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
    --if not isOwn then
    --    fashionId = t.DefaultFashionId
    --else
    --    local character = XMVCA.XCharacter:GetCharacter(characterId)
    --    --随机涂装，则采用配置
    --    if character.RandomFashion then
    --        fashionId = t.DefaultFashionId
    --    else
    --        fashionId = character.FashionId
    --    end
    --end
    fashionId = t.DefaultFashionId
    char:SetFashionId(fashionId)
    return fashionId
end

function XBigWorldCharacterModel:GetHeadInfo(characterId)
    local char = self:GetDlcCharacter(characterId)
    local info = char:GetHeadInfo()
    if info then
        return info
    end
    --local t = XDataCenter.FashionManager.GetHeadPortraitList(characterId)
    info = {
        HeadFashionId = self:GetFashionId(characterId),
        HeadFashionType = XFashionConfigs.HeadPortraitType.Default
    }
    char:SetHeadInfo(info.HeadFashionId, info.HeadFashionType)
    
    return info
end

function XBigWorldCharacterModel:GetDlcCharacter(id)
    if self._CharDict[id] then
        return self._CharDict[id]
    end
    if not XBigWorldCharacter then
        XBigWorldCharacter = require("XModule/XBigWorldCharacter/Data/XBigWorldCharacter")
    end
    local char = XBigWorldCharacter.New(id)
    self._CharDict[id] = char
    
    return char
end

-- region CharacterUiEffect

---@return XTableBigWorldCharacterUiEffect[]
function XBigWorldCharacterModel:GetDlcCharacterUiEffectTemplates()
    return self._ConfigUtil:GetByTableKey(TableCharacter.BigWorldCharacterUiEffect) or {}
end

---@return table<number, table<string, table<string, XBigWorldCharacterUiEffectInfo>>>
function XBigWorldCharacterModel:GetCharacterUiEffectMap()
    if not self._CharacterUiEffectMap then
        local configs = self:GetDlcCharacterUiEffectTemplates()
        local defaultAction = "DefaultAction"
        local defaultRoot = "Root"

        self._CharacterUiEffectMap = {}
        for id, config in pairs(configs) do
            local fashionId = config.FashionId
            local actionId = config.ActionId or defaultAction
            local rootName = config.EffectRootName or defaultRoot
            
            if not self._CharacterUiEffectMap[fashionId] then
                self._CharacterUiEffectMap[fashionId] = {}
            end
            if not self._CharacterUiEffectMap[fashionId][actionId] then
                self._CharacterUiEffectMap[fashionId][actionId] = {}
            end
            
            local effectIds = config.EffectIds
            
            if not XTool.IsTableEmpty(effectIds) then
                local effectInfo = self._CharacterUiEffectMap[fashionId][actionId][rootName]
                
                if not effectInfo then
                    effectInfo = XBigWorldCharacterUiEffectInfo.New(fashionId, actionId, rootName)
                end

                for _, effectId in pairs(effectIds) do
                    effectInfo:AddEffectId(effectId)
                end
            end
        end
    end

    return self._CharacterUiEffectMap
end

---@return table<string, XBigWorldCharacterUiEffectInfo>
function XBigWorldCharacterModel:GetCharacterUiEffectInfos(fashionId, actionId)
    local effectMap = self:GetCharacterUiEffectMap()
    
    actionId = actionId or "DefaultAction"

    return effectMap[fashionId][actionId]
end

-- endregion

-- region 试用角色

function XBigWorldCharacterModel:UpdateTrialCharacterIds(characterIds, isCover)
    self:ClearTrialCharacterIds()
    self._IsTrialCoverTeam = isCover or false

    if not characterIds then
        XTool.LoopCollection(characterIds, function(characterId)
            table.insert(self._TrialCharacterIds, characterId)
            self._TrialCharacterMap[characterId] = true
        end)
    end
end

function XBigWorldCharacterModel:ClearTrialCharacterIds()
    self._TrialCharacterIds = {}
    self._TrialCharacterMap = {}
    self._IsTrialCoverTeam = false
end

function XBigWorldCharacterModel:CheckTrialCharacter(characterId)
    if XTool.IsNumberValid(characterId) then
        return self._TrialCharacterMap[characterId] or false
    end

    return false
end

-- endregion

return XBigWorldCharacterModel