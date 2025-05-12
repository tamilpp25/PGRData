--- 封装的数值类，可接受临时的修正
---@class XBagOrganizeNumVal
---@field MultyBuffDict table
---@field AddsBuffDict table
---@field Owner XBagOrganizeScopeEntity
---@field private _OriginVal number @原始值，即未经过任何buff临时修正的值
---@field private _FinalVal @最终值，即经过所有buff临时修正后的值
local XBagOrganizeNumVal = XClass(nil, 'XBagOrganizeNumVal')

function XBagOrganizeNumVal:Ctor(owner)
    self.Owner = owner
    self._OriginVal = 0
    self._FinalVal = 0
    self._FinalValNeedRefresh = true
end

function XBagOrganizeNumVal:SetOriginVal(value)
    self._OriginVal = value
    self._FinalValNeedRefresh = true
end

function XBagOrganizeNumVal:GetOriginVal()
    return self._OriginVal
end

function XBagOrganizeNumVal:GetFinalVal()
    if self._FinalValNeedRefresh then
        self:_RefreshFinalVal()
        self._FinalValNeedRefresh = false
    end
    
    return self._FinalVal
end

--- 获取最终整型值(向下取整）
function XBagOrganizeNumVal:GetFinalValInt()
    return XMath.ToMinInt(self:GetFinalVal())
end

--- 获取最终整型值（向上取整）
function XBagOrganizeNumVal:GetFinalValIntCeil()
    return math.ceil(self:GetFinalVal())
end

function XBagOrganizeNumVal:_RefreshFinalVal()
    -- 当前修正计算规则：原值 + Math.IntCeil(原值 * 乘法修正值1) + Math.IntCeil(原值 * 乘法修正值2) + ... + 加法修正
    
    local totalVal = self._OriginVal
    
    
    if not XTool.IsTableEmpty(self.MultyBuffDict) then
        local multyParts = {}
        
        -- 同类型的buff合并
        for buffId, val in pairs(self.MultyBuffDict) do
            ---@type XBagOrganizeBuff
            local buffData = self.Owner:GetBuffDataByBuffId(buffId)

            if multyParts[buffData.BuffType] == nil then
                multyParts[buffData.BuffType] = val
            else
                multyParts[buffData.BuffType] = multyParts[buffData.BuffType] + val
            end
        end
        
        -- 分别计算每个类型的乘法修正的向上取整值
        for i, multy in pairs(multyParts) do
            totalVal = totalVal + math.ceil(self._OriginVal * multy)
        end
    end
    
    if not XTool.IsTableEmpty(self.AddsBuffDict) then
        local addsTotal = 0

        for buffId, val in pairs(self.AddsBuffDict) do
            addsTotal = addsTotal + val
        end

        totalVal = totalVal + addsTotal
    end

    self._FinalVal = totalVal
end

function XBagOrganizeNumVal:AddMultyBuff(buffId, multyVal)
    if self.MultyBuffDict == nil then
        self.MultyBuffDict = {}
    end

    if self.MultyBuffDict[buffId] then
        XLog.Error('重复为实体:'..tostring(self.Owner.Id)..' 添加buff：'..tostring(buffId))
        return
    end

    self.MultyBuffDict[buffId] = multyVal
    self._FinalValNeedRefresh = true
end

function XBagOrganizeNumVal:RemoveMultyBuff(buffId)
    if not XTool.IsTableEmpty(self.MultyBuffDict) then
        if self.MultyBuffDict[buffId] then
            self.MultyBuffDict[buffId] = nil
            self._FinalValNeedRefresh = true
            return
        end
    end

    XLog.Error('重复对实体:'..tostring(self.Owner.Id)..' 移除buff：'..tostring(buffId))
end

function XBagOrganizeNumVal:AddAddsBuff(buffId, addsVal)
    if self.AddsBuffDict == nil then
        self.AddsBuffDict = {}
    end

    if self.AddsBuffDict[buffId] then
        XLog.Error('重复为实体:'..tostring(self.Owner.Id)..' 添加buff：'..tostring(buffId))
        return
    end

    self.AddsBuffDict[buffId] = addsVal
    self._FinalValNeedRefresh = true
end

function XBagOrganizeNumVal:RemoveAddsBuff(buffId)
    if not XTool.IsTableEmpty(self.AddsBuffDict) then
        if self.AddsBuffDict[buffId] then
            self.AddsBuffDict[buffId] = nil
            self._FinalValNeedRefresh = true
            return
        end
    end

    XLog.Error('重复对实体:'..tostring(self.Owner.Id)..' 移除buff：'..tostring(buffId))
end

--- 获取指定buff类型的乘法修正带来的增量，用于外部显示
function XBagOrganizeNumVal:GetMultyBuffAddsByBuffType(buffType)
    if not XTool.IsTableEmpty(self.MultyBuffDict) then
        local multyTotal = 0
        
        for buffId, multyVal in pairs(self.MultyBuffDict) do
            -- 查找挂载在所属实体上的buff数据
            ---@type XBagOrganizeBuff
            local buff = self.Owner:GetBuffDataByBuffId(buffId)

            if buff and buff.BuffType == buffType then
                multyTotal = multyTotal + multyVal
            end
        end
        
        return multyTotal * self._OriginVal
    end
    return 0
end

--- 获取指定buff类型的加法修正带来的增量，用于外部显示
function XBagOrganizeNumVal:GetAddsBuffAddsByBuffType(buffType)
    if not XTool.IsTableEmpty(self.AddsBuffDict) then
        local addsTotal = 0

        for buffId, addsVal in pairs(self.AddsBuffDict) do
            -- 查找挂载在所属实体上的buff数据
            ---@type XBagOrganizeBuff
            local buff = self.Owner:GetBuffDataByBuffId(buffId)

            if buff and buff.BuffType == buffType then
                addsTotal = addsTotal + addsVal
            end
        end

        return addsTotal
    end
    return 0
end

return XBagOrganizeNumVal