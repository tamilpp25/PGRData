---@class XPcgToken
local XPcgToken = XClass(nil, "XPcgToken")

function XPcgToken:Ctor()
    -- token表id
    ---@type number
    self.Id = 0
    -- 层数
    ---@type number
    self.Layer = 0
    -- 动态值, 加层时加值, 根据token配置决定意义
    self.ValueOnAdd = 0
end

function XPcgToken:RefreshData(data)
    self.Id = data.Id or 0
    self.Layer = data.Layer or 0
    self.ValueOnAdd = data.ValueOnAdd or 0
end

function XPcgToken:GetId()
    return self.Id
end

function XPcgToken:GetLayer()
    return self.Layer
end

function XPcgToken:SetLayer(layer)
    self.Layer = layer
end

function XPcgToken:GetValueOnAdd()
    return self.ValueOnAdd
end

return XPcgToken