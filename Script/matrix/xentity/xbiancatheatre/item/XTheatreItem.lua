local type = type

local Default = {
    _Uid = 0,       --唯一Id
    _ItemId = 0,    --TheatreItem表的Id
}

--道具
local XTheatreItem = XClass(nil, "XTheatreItem")

function XTheatreItem:Ctor(uid)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if uid then
        self._Uid = uid
    end
    self._IsActive = false
    self._Count = 0 --道具数量
end

function XTheatreItem:GetId()
    return self._Uid
end

function XTheatreItem:UpdateData(itemId)
    self._ItemId = itemId
    self._IsActive = true
end

function XTheatreItem:AddCount()
    self._Count = self._Count + 1
end

function XTheatreItem:RemoveCount()
    self._Count = self._Count - 1
end

function XTheatreItem:GetItemCount()
    return self._Count
end

function XTheatreItem:IsActive()
    return self._IsActive
end

function XTheatreItem:GetItemId()
    return self._ItemId
end

function XTheatreItem:GetType()
    return XBiancaTheatreConfigs.GetTheatreItemType(self:GetItemId())
end

function XTheatreItem:GetName()
    local id = self:GetItemId()
    local itemId = XBiancaTheatreConfigs.GetTheatreItemId(id)
    return XItemConfigs.GetItemNameById(itemId)
end

function XTheatreItem:GetIcon()
    local id = self:GetItemId()
    local itemId = XBiancaTheatreConfigs.GetTheatreItemId(id)
    return XItemConfigs.GetItemIconById(itemId)
end

function XTheatreItem:GetQualityIcon()
    local id = self:GetItemId()
    local itemId = XBiancaTheatreConfigs.GetTheatreItemId(id)
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    return XBiancaTheatreConfigs.GetClientConfig("SkillQualityIcon", quality)
end

function XTheatreItem:GetItemQualityIcon()
    local id = self:GetItemId()
    local itemId = XBiancaTheatreConfigs.GetTheatreItemId(id)
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    return XArrangeConfigs.GeQualityPath(quality)
end

--获得描述
function XTheatreItem:GetDescription()
    local id = self:GetItemId()
    local itemId = XBiancaTheatreConfigs.GetTheatreItemId(id)
    return XDataCenter.ItemManager.GetItemDescription(itemId)
end

--获得获取途径
function XTheatreItem:GetExplain()
    local id = self:GetItemId()
    return XBiancaTheatreConfigs.GetTheatreItemExplain(id)
end

return XTheatreItem