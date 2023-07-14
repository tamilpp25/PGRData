local XTRPGRoleTalent = require("XEntity/XTRPG/XTRPGRoleTalent")
local XTRPGRoleAttribute = require("XEntity/XTRPG/XTRPGRoleAttribute")

local type = type
local tableInsert = table.insert
local RoleAttributeType = XTRPGConfigs.RoleAttributeType

local Default = {
    __Id = 0,
    __Attributes = {},
    __Talents = {},
    __UsedTalentPoint = 0,
    __BuffIds = {},
}

local XTRPGRole = XClass(nil, "XTRPGRole")

function XTRPGRole:Ctor(characterId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = characterId
    self:InitAttributes()
    self:InitTalents()
end

function XTRPGRole:UpdateData(data)
    if not data then return end

    self.__BuffIds = data.BuffIds or {}
    self:UpdateAtrributes(data.Attributes)
    self:UpdateTalent(data.TalentIds)
end

----------------------------------------------属性相关 begin--------------------------------
function XTRPGRole:InitAttributes()
    for _, attributeType in pairs(RoleAttributeType) do
        local initValue = XTRPGConfigs.GetRoleInitAttribute(self.__Id, attributeType)
        self.__Attributes[attributeType] = XTRPGRoleAttribute.New(attributeType, initValue)
    end
end

function XTRPGRole:UpdateAtrributes(datas)
    if XTool.IsTableEmpty(datas) then return end
    for _, data in pairs(datas) do
        local attributeType = data.Id
        local attribute = self:GetAttribute(attributeType)
        attribute:UpdateData(data)
    end
end

function XTRPGRole:GetAttribute(attributeType)
    local attribute = self.__Attributes[attributeType]
    if not attribute then
        XLog.Error("XTRPGRole:GetAttribute Error: 获取角色属性错误, attributeType: " .. attributeType)
        return
    end
    return attribute
end

function XTRPGRole:GetAttributeMinRollValue(attributeType)
    local attribute = self:GetAttribute(attributeType)
    return attribute:GetMinRollValue()
end

function XTRPGRole:GetAttributeMaxRollValue(attributeType)
    local attribute = self:GetAttribute(attributeType)
    return attribute:GetMaxRollValue()
end

function XTRPGRole:GetAttributes()
    local attributes = {}
    for attrType, attribute in pairs(self.__Attributes) do
        local attribute = {
            Type = attrType,
            Value = attribute:GetValue(),
        }
        tableInsert(attributes, attribute)
    end
    return attributes
end
----------------------------------------------属性相关 end--------------------------------
----------------------------------------------天赋相关 begin--------------------------------
function XTRPGRole:InitTalents()
    local roleId = self.__Id
    local configs = XTRPGConfigs.GetRoleTalentGroupConfig(roleId)

    for talentId in pairs(configs) do
        local talent = XTRPGRoleTalent.New(talentId)
        talent:Init(roleId)
        self.__Talents[talentId] = talent
    end
end

function XTRPGRole:UpdateTalent(talentIds)
    if not talentIds then return end

    self.__UsedTalentPoint = 0
    for _, talent in pairs(self.__Talents) do
        talent:SetActive(false)
    end

    for _, talentId in pairs(talentIds) do
        self:ActiveTalent(talentId)
    end
end

function XTRPGRole:GetTalent(talentId)
    local talent = self.__Talents[talentId]
    if not talent then
        XLog.Error("XTRPGRole:GetTalent Error:: 获取角色天赋错误, talentId: " .. talentId)
        return
    end
    return talent
end

function XTRPGRole:GetTalentIds()
    local talentIds = {}
    for talentId in pairs(self.__Talents) do
        tableInsert(talentIds, talentId)
    end
    return talentIds
end

function XTRPGRole:GetCommonTalentIds()
    local talentIds = {}
    for talentId in pairs(self.__Talents) do
        if XTRPGConfigs.IsRoleTalentCommonForShow(self.__Id, talentId)
        and self:IsTalentActive(talentId)
        then
            tableInsert(talentIds, talentId)
        end
    end
    return talentIds
end

function XTRPGRole:CanActiveTalent(talentId)
    local preId = XTRPGConfigs.GetRoleTalentPreId(self.__Id, talentId)
    if not preId or preId == 0 then return true end
    return self:IsTalentActive(preId)
end

function XTRPGRole:CanActiveAnyTalent()
    for talentId in pairs(self.__Talents) do
        if self:CanActiveTalent(talentId)
        and not self:IsTalentActive(talentId)
        and XDataCenter.TRPGManager.IsActiveTalentCostEnough(self.__Id, talentId)
        then
            return true
        end
    end
    return false
end

function XTRPGRole:ActiveTalent(talentId)
    local talent = self:GetTalent(talentId)
    talent:SetActive(true)

    local costPoint = talent:GetCostPoint()
    self.__UsedTalentPoint = self.__UsedTalentPoint + costPoint
end

function XTRPGRole:IsTalentActive(talentId)
    local talent = self:GetTalent(talentId)
    return talent:IsActive()
end

function XTRPGRole:IsAnyTalentActive()
    for _, talent in pairs(self.__Talents) do
        if talent:IsActive() then
            return true
        end
    end
    return false
end

function XTRPGRole:GetTalentCostPoint(talentId)
    local talent = self:GetTalent(talentId)
    return talent:GetCostPoint()
end

function XTRPGRole:GetUsedTalentPoint()
    return self.__UsedTalentPoint
end
----------------------------------------------天赋相关 end--------------------------------
----------------------------------------------Buff相关 begin--------------------------------
function XTRPGRole:IsHaveBuffUp()
    if self:IsHaveBuffDown() then return false end
    for _, buffId in pairs(self.__BuffIds) do
        if XTRPGConfigs.IsBuffUp(buffId) then
            return true
        end
    end
    return false
end

function XTRPGRole:IsHaveBuffDown()
    for _, buffId in pairs(self.__BuffIds) do
        if XTRPGConfigs.IsBuffDown(buffId) then
            return true
        end
    end
    return false
end

function XTRPGRole:GetBuffIds()
    return XTool.Clone(self.__BuffIds)
end
----------------------------------------------Buff相关 end--------------------------------
return XTRPGRole