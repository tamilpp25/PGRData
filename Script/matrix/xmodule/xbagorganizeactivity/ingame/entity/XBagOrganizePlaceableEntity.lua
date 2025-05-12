--- 可放置类实体的基类
---@class XBagOrganizePlaceableEntity:XBagOrganizeScopeEntity
local XBagOrganizePlaceableEntity = XClass(require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeScopeEntity'), 'XBagOrganizePlaceableEntity')

function XBagOrganizePlaceableEntity:Ctor()
    self._LeftUpX = 0
    self._LeftUpY = 0
    self._RotateTimes = 0 -- 顺时针旋转次数
    self._Blocks = nil
end

function XBagOrganizePlaceableEntity:GetType()
    return XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Placeable
end

function XBagOrganizePlaceableEntity:SetData(id, uid, blocks)
    self.Id = id
    self.Uid = uid
    self.ComposeId = self.Uid * 10000 + self.Id
    self._RotateTimes = 0
    self._Blocks = XTool.Clone(blocks)
end

--- 设置货物的中心位置
--- 对应的是4x4网格中(1,1)位置的格子,即网格左上角
function XBagOrganizePlaceableEntity:SetLeftUp(x, y)
    self._LeftUpX = x
    self._LeftUpY = y
end

function XBagOrganizePlaceableEntity:GetLeftUpX()
    return self._LeftUpX
end

function XBagOrganizePlaceableEntity:GetLeftUpY()
    return self._LeftUpY
end

function XBagOrganizePlaceableEntity:GetRotateTimes()
    return self._RotateTimes
end

function XBagOrganizePlaceableEntity:GetBlocks()
    return self._Blocks
end

function XBagOrganizePlaceableEntity:SetRotateTimes(times)
    
end

return XBagOrganizePlaceableEntity
