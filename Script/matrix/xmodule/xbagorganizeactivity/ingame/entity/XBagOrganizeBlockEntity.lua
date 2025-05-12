--- 背包网格实体
---@class XBagOrganizeBlockEntity: XBagOrganizeScopeEntity
local XBagOrganizeBlockEntity = XClass(require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeScopeEntity'), 'XBagOrganizeBlockEntity')

function XBagOrganizeBlockEntity:Ctor(x, y)
    self._X = x
    self._Y = y
end

function XBagOrganizeBlockEntity:SetEnabled(isEnable)
    self.Enabled = isEnable
end

--- 地块的清空标签方法，目前不会使用buff机制对地块添加tag
--- 但逻辑扩展需要注意仅清空手动添加的tag，不然会导致buff系统出问题
function XBagOrganizeBlockEntity:ClearTags()
    self:RemoveTag(XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods, true)
    self:RemoveTag(XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Normal, true)
    self:RemoveTag(XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Empty, true)
end

return XBagOrganizeBlockEntity