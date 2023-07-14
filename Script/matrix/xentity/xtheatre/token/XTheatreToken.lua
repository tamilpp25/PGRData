local type = type

local Default = {
    _Id = 0, --TheatreItem表的Id
    _FightCount = 0, --使用信物战斗的次数
    _Lv = 0
}

--信物和道具
local XTheatreToken = XClass(nil, "XTheatreToken")

--id：TheatreItem表的Id
function XTheatreToken:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._Id = id
    self._IsActive = false
end

function XTheatreToken:GetId()
    return self._Id
end

function XTheatreToken:UpdateData(data)
    if data.FightCount then
        self._FightCount = data.FightCount
    end
    self._Lv = data.Lv
    self._IsActive = true
end

function XTheatreToken:UpdateLv(lv)
    self._Lv = lv
end

function XTheatreToken:IsActive()
    if not self:IsToken() then
        return true
    end
    return self._IsActive
end

function XTheatreToken:GetLv()
    return self._Lv
end

function XTheatreToken:GetFightCount()
    return self._FightCount
end

function XTheatreToken:IsToken()
    return self:GetType() == XTheatreConfigs.ItemType.Token
end

function XTheatreToken:GetType()
    return XTheatreConfigs.GetTheatreItemType(self:GetId())
end

function XTheatreToken:GetName()
    local id = self:GetId()
    if self:IsToken() then
        local keepsakeId = self:GetKeepsakeId()
        return XTheatreConfigs.GetTheatreKeepsakeName(keepsakeId)
    end

    local itemId = XTheatreConfigs.GetTheatreItemId(id)
    return XItemConfigs.GetItemNameById(itemId)
end

function XTheatreToken:GetIcon()
    local id = self:GetId()
    if self:IsToken() then
        local keepsakeId = self:GetKeepsakeId()
        return XTheatreConfigs.GetTheatreKeepsakeIcon(keepsakeId)
    end

    local itemId = XTheatreConfigs.GetTheatreItemId(id)
    return XItemConfigs.GetItemIconById(itemId)
end

function XTheatreToken:GetQualityIcon()
    local id = self:GetId()
    local quality
    if self:IsToken() then
        quality = XTheatreConfigs.GetTheatreItemQuality(id)
    else
        local itemId = XTheatreConfigs.GetTheatreItemId(id)
        quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    end

    return XTheatreConfigs.GetClientConfig("SkillQualityIcon", quality)
end

function XTheatreToken:GetItemQualityIcon()
    local id = self:GetId()
    local quality
    if self:IsToken() then
        quality = XTheatreConfigs.GetTheatreItemQuality(id)
    else
        local itemId = XTheatreConfigs.GetTheatreItemId(id)
        quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    end
    return XArrangeConfigs.GeQualityPath(quality)
end

--获得描述
function XTheatreToken:GetDescription()
    local id = self:GetId()
    if self:IsToken() then
        local keepsakeId = self:GetKeepsakeId()
        return XTheatreConfigs.GetTheatreKeepsakeDescription(keepsakeId)
    end

    local itemId = XTheatreConfigs.GetTheatreItemId(id)
    return XDataCenter.ItemManager.GetItemDescription(itemId)
end

--获得获取途径
function XTheatreToken:GetExplain()
    local id = self:GetId()
    return XTheatreConfigs.GetTheatreItemExplain(id)
end

function XTheatreToken:GetKeepsakeId()
    local id = self:GetId()
    return XTheatreConfigs.GetTheatreItemKeepsakeId(id)
end

return XTheatreToken