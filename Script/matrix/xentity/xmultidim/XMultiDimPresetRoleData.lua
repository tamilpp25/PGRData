local type = type
local pairs = pairs

--[[
[MessagePackObject(true)]
public class XMultiDimPrefabCharacter
{
    public int CareerId;

    public List<int> CharacterIds = new List<int>();
}
]]

local Default = {
    _CareerId = 0, -- 职业Id
    _CharacterIds = {}, -- 预选角色Id
}
    
---@class XMultiDimPresetRoleData
local XMultiDimPresetRoleData = XClass(nil, "XMultiDimPresetRoleData")

function XMultiDimPresetRoleData:Ctor(careerId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._CareerId = careerId
    
    self._CharacterIds = XDataCenter.TeamManager.CreateTeam(careerId)
    self._CharacterIds:UpdateAutoSave(false)
    self._CharacterIds:Clear()

    -- 克隆一个对象 用于保存临时数据
    self.DefaultCharacterIds = XTool.Clone(self._CharacterIds)
    self:UpdateDefaultCharacterIds()
end

function XMultiDimPresetRoleData:UpdateCharacterData(characterIds)
    if not XTool.IsTableEmpty(characterIds) then
        for index, charId in pairs(characterIds) do
            self._CharacterIds:UpdateEntityTeamPos(charId, index, true)
        end
        self:UpdateDefaultCharacterIds()
    end
end

function XMultiDimPresetRoleData:UpdateDefaultCharacterIds()
    self.DefaultEntityIds = {}
    local entityIds = self._CharacterIds:GetEntityIds()
    for _, charId in pairs(entityIds) do
        if XTool.IsNumberValid(charId) then
            table.insert(self.DefaultEntityIds, charId)
        end
    end
    
    for index, charId in pairs(entityIds) do
        local defaultCharId = charId
        if not XTool.IsNumberValid(charId) then
            defaultCharId = self:GetDefaultCharId()
            if XTool.IsNumberValid(defaultCharId) then
                table.insert(self.DefaultEntityIds, defaultCharId)
            end
        end
        self.DefaultCharacterIds:UpdateEntityTeamPos(defaultCharId, index, true)
    end
end

function XMultiDimPresetRoleData:GetDefaultCharId()
    local tempCharacterList = self:GetCharacterAbilityTopThree()
    local defaultCharId = 0
    for i = 1, #tempCharacterList do
        local entity = tempCharacterList[i]
        if entity and entity.GetCharacterViewModel then
            local characterViewModel = entity:GetCharacterViewModel()
            local charId = characterViewModel:GetId()
            if not table.contains(self.DefaultEntityIds, charId)  then
                defaultCharId = charId
                break
            end
        end
    end
    return defaultCharId
end

function XMultiDimPresetRoleData:GetEntityIds()
    return self.DefaultCharacterIds:GetEntityIds()
end

function XMultiDimPresetRoleData:GetTeam()
    return self.DefaultCharacterIds
end
-- 返回当前职业预选角色最大的战力
function XMultiDimPresetRoleData:GetHighAbility()
    local entityIds = self.DefaultCharacterIds:GetEntityIds()
    local maxAbility = 0
    for _, entityId in pairs(entityIds) do
        local entity = XDataCenter.CharacterManager.GetCharacter(entityId)
        if not entity or not entity.GetCharacterViewModel then
            goto CONTINUE
        end
        
        local characterViewModel = entity:GetCharacterViewModel()
        local ability = characterViewModel:GetAbility()

        if ability > maxAbility then
            maxAbility = ability
        end
        
        :: CONTINUE ::
    end
    return maxAbility
end

function XMultiDimPresetRoleData:GetCharacterAbilityTopThree()
    local tempCharacterList = self:GetOwnCharacterListByFilterCareer()
    -- 通过战力排序
    table.sort(tempCharacterList, function(a, b)
        return a.Ability > b.Ability
    end)
    return tempCharacterList
end

function XMultiDimPresetRoleData:GetOwnCharacterListByFilterCareer(characterType)
    local tempCharacterList = {}
    -- 获取已拥有的角色
    local ownCharacterList = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
    -- 通过角色职业过滤
    for _, character in pairs(ownCharacterList) do
        if self:CheckFilterJudge(character) then
            table.insert(tempCharacterList, character)
        end
    end
    return tempCharacterList
end

function XMultiDimPresetRoleData:CheckFilterJudge(entity)
    if not entity.GetCharacterViewModel then
        return false
    end
    local characterViewModel = entity:GetCharacterViewModel()
    local filterCareer = XMultiDimConfig.GetMultiDimCareerFilterCareer(self._CareerId)
    for _, career in pairs(filterCareer) do
        if career == characterViewModel:GetCareer() then
            return true
        end
    end
    return false
end

return XMultiDimPresetRoleData