--- 简单的Buff类, 仅支持修正数值字段、添加标记两种逻辑
---@class XBagOrganizeBuff
---@field ConfigId
---@field BuffType
---@field EffectAimId @目标主体的Id
---@field EffectFieldName @目标字段
---@field MultyValue @乘法修正
---@field AddsValue @加法修正
---@field AddTag any @任意类型的标签
local XBagOrganizeBuff = XClass(nil, 'XBagOrganizeBuff')

function XBagOrganizeBuff:Ctor(scopeFindHandle, recycleHandle)
    self.ScopeFindHandle = scopeFindHandle
    self.RecycleHandle = recycleHandle
end

--- 因为外部可直接获得scope实例，因此直接作为参数传入
---@param scope XBagOrganizeScopeEntity
function XBagOrganizeBuff:AddBuff(scope)
    self.EffectAimId = scope.Id
    
    -- 修正数值
    if not string.IsNilOrEmpty(self.EffectFieldName) then
        ---@type XBagOrganizeNumVal
        local field = scope[self.EffectFieldName]
        -- 乘法修正
        if XTool.IsNumberValid(self.MultyValue) and field and field.__cname == 'XBagOrganizeNumVal' then
            field:AddMultyBuff(self.ConfigId, self.MultyValue)
        end
        
        -- 加法修正
        if XTool.IsNumberValid(self.AddsValue) and field and field.__cname == 'XBagOrganizeNumVal' then
            field:AddAddsBuff(self.ConfigId, self.AddsValue)
        end
    end
    
    -- 添加标记
    if self.AddTag ~= nil then
        scope:AddTag(self.AddTag)
    end
    
    -- 添加到实体身上
    scope:AddBuffRef(self)
end

--- 移除buff，通过给定的查找目标接口查找，方便buff实体在外部被管理（而非scope内）时进行移除操作
function XBagOrganizeBuff:RemoveBuff()
    ---@type XBagOrganizeScopeEntity
    local scope = self.ScopeFindHandle(self.EffectAimId)

    if not scope then
        XLog.Error('找不到影响的实体Id:'..tostring(self.EffectAimId))
        return
    end
    
    self:ClearBuffEffect(scope)

    -- 从实体身上移除自己
    scope:RemoveBuffRef(self)
end

--- 消除buff的效果
function XBagOrganizeBuff:ClearBuffEffect(scope)
    -- 移除修正
    if not string.IsNilOrEmpty(self.EffectFieldName) then
        ---@type XBagOrganizeNumVal
        local field = scope[self.EffectFieldName]
        -- 移除乘法修正
        if XTool.IsNumberValid(self.MultyValue) and field and field.__cname == 'XBagOrganizeNumVal' then
            field:RemoveMultyBuff(self.ConfigId)
        end
        -- 移除加法修正
        if XTool.IsNumberValid(self.AddsValue) and field and field.__cname == 'XBagOrganizeNumVal' then
            field:RemoveAddsBuff(self.ConfigId)
        end
    end

    -- 移除标记
    if self.AddTag ~= nil then
        scope:RemoveTag(self.AddTag)
    end
end

function XBagOrganizeBuff:ResetData()
    self.ConfigId = nil
    self.EffectAimId = nil
    self.EffectFieldName = nil
    self.MultyValue = nil
    self.AddsValue = nil
    self.AddTag = nil
end

--- 通过回收回调对自己进行回收，该函数用于对象不方便直接查找所属对象池时使用，需确保外部调用后立刻解开引用
function XBagOrganizeBuff:Recycle()
    if self.RecycleHandle then
        self.RecycleHandle(self)
    end
end

return XBagOrganizeBuff