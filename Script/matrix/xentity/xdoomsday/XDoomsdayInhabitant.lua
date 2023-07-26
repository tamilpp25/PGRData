local XDoomsdayAttribute = require("XEntity/XDoomsday/XDoomsdayAttribute")

local Default = {
    _Id = 0,
    _AttributeDic = {}, --居民属性
    _WorkingBuildingId = 0, --工作建筑Id
    _LivingBuildingId = 0 --居住建筑Id（自动分配，仅用于判断无家可归）
}

local AttrType2BadKeyName = { 
    [XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER] = "DailyChangeValueWhenHungery", 
    [XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH] = "DailyChangeValueWhenSick"
}

--末日生存玩法-居民
local XDoomsdayInhabitant = XClass(XDataEntityBase, "XDoomsdayInhabitant")

function XDoomsdayInhabitant:Ctor()
    self:Init(Default)

    self._AttributeDic = {}
    for _, attrType in ipairs(XDoomsdayConfigs.GetSortedAttrTypes()) do
        self._AttributeDic[attrType] = XDoomsdayAttribute.New(attrType)
    end
end

function XDoomsdayInhabitant:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_WorkingBuildingId", data.WorkingBuildingId)
    self:SetProperty("_LivingBuildingId", data.LivingBuildingId)

    self:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH):SetProperty("_Value", data.Heath)
    self:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER):SetProperty("_Value", data.Hunger)
    self:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN):SetProperty("_Value", data.Mental)
end

--是否无家可归
function XDoomsdayInhabitant:IsHomeless()
    return not XTool.IsNumberValid(self._LivingBuildingId)
end

--是否空闲
function XDoomsdayInhabitant:IsIdle()
    return not XTool.IsNumberValid(self._WorkingBuildingId)
end

--根据属性类型获取属性
function XDoomsdayInhabitant:GetAttr(attrType)
    return self._AttributeDic[attrType]
end

function XDoomsdayInhabitant:GetTodayValue(attrId, attrType)
    local attr = self:GetAttr(attrType)
    local value = attr:GetProperty("_Value")
    if attr:IsBad() then
        local key = AttrType2BadKeyName[attrType]
        local downValue = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, key) or 0
        --取的值为负数
        value = value + downValue
    end
    if self:IsHomeless() then
        local downValue = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "DailyChangeValueWhenNoHome") or 0
        --取的值为负数
        value = value + downValue
    end
    return value
end

return XDoomsdayInhabitant
