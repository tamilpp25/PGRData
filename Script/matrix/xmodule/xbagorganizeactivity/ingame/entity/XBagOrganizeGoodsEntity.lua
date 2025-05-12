--- 货物的实体
---@class XBagOrganizeGoodsEntity: XBagOrganizePlaceableEntity
local XBagOrganizeGoodsEntity = XClass(require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizePlaceableEntity'), 'XBagOrganizeGoodsEntity')

function XBagOrganizeGoodsEntity:Ctor()
    self.Id = nil
    self.Uid = nil
    self._IsValid = false -- 是否有效：即使真的放置了，也可能因为各种原因导致它不被计入总分
    ---@type XBagOrganizeNumVal
    self.Value = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeNumVal').New(self)
end

---@overload
function XBagOrganizeGoodsEntity:SetData(id, uid, blocks, originVal)
    self.Super.SetData(self, id, uid, blocks)
    self.Value:SetOriginVal(originVal)
end

---@overload
function XBagOrganizeGoodsEntity:GetType()
    return XMVCA.XBagOrganizeActivity.EnumConst.EntityType.Goods
end

---@overload
function XBagOrganizeGoodsEntity:SetRotateTimes(times)
    times = times >= 4 and 0 or times
    self._RotateTimes = times

    -- 执行一次旋转
    local stack = {}
    for x = 4, 1, -1 do
        for y = 0, 3 do
            local index = x + y * 4
            table.insert(stack, self._Blocks[index])
        end
    end

    local index = 1
    for i = #stack, 1, -1 do
        self._Blocks[index] = stack[i]
        index = index + 1
    end
end

function XBagOrganizeGoodsEntity:GetIsValid()
    return self._IsValid
end

function XBagOrganizeGoodsEntity:SetIsValid(isValid)
    self._IsValid = isValid
end

return XBagOrganizeGoodsEntity