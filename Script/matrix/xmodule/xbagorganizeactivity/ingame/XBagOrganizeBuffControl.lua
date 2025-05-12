--- 玩法内分管buff系统的控制器
---@class XBagOrganizeBuffControl: XControl
---@field private _MainControl XBagOrganizeActivityGameControl
---@field private _Model XBagOrganizeActivityModel
---@field BuffPool XPool
local XBagOrganizeBuffControl = XClass(XControl, 'XBagOrganizeBuffControl')
local XBagOrganizeBuff = require('XModule/XBagOrganizeActivity/InGame/Entity/XBagOrganizeBuff')

function XBagOrganizeBuffControl:OnInit()
    self._ScopeFindHandler = handler(self._MainControl, self._MainControl.GetScopeEntityById)
    
    -- buff的对象池
    self.BuffPool = XPool.New(function()
        return XBagOrganizeBuff.New(self._ScopeFindHandler, self._BuffRecycleHandler)
    end,
    function(buff)
        buff:ResetData()
    end, false)

    self._BuffRecycleHandler = handler(self.BuffPool, self.BuffPool.ReturnItemToPool)

end

function XBagOrganizeBuffControl:OnRelease()

end

--region ---------- Buff相关接口 ---------->>>

-- 因为buff没有数据持久化到配置表中，且目前也没有复杂的自定义buff，直接在这里定义现成的几类buff的获取

--- 获取添加标签型Buff
function XBagOrganizeBuffControl:GetTagBuff(buffType, tag)
    ---@type XBagOrganizeBuff
    local buff = self.BuffPool:GetItemFromPool()

    buff.BuffType = buffType
    buff.AddTag = tag

    return buff
end

--- 获取添加乘法修正型Buff
function XBagOrganizeBuffControl:GetMultyModifierBuff(buffType, multy, fieldName)
    ---@type XBagOrganizeBuff
    local buff = self.BuffPool:GetItemFromPool()

    buff.BuffType = buffType
    buff.MultyValue = multy
    buff.EffectFieldName = fieldName

    return buff
end

--- 获取添加加法修正型Buff
function XBagOrganizeBuffControl:GetAddsModifierBuff(buffType, adds, fieldName)
    ---@type XBagOrganizeBuff
    local buff = self.BuffPool:GetItemFromPool()

    buff.BuffType = buffType
    buff.AddsValue = adds
    buff.EffectFieldName = fieldName

    return buff
end

--endregion <<<-------------------------------------

return XBagOrganizeBuffControl