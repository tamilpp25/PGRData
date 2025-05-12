---具有可被施加影响范围的实体，通用化支持诸如buff、modifier功能
---@class XBagOrganizeScopeEntity
---@field Id
---@field TagDict table<any, number> @任意类型的标记，来源不固定，表示该实体拥有的某些特质，为外部逻辑执行提供支持
---@field BuffDict table<XBagOrganizeBuff, boolean> @挂载的Buff引用，方便显示单个主体接收的buff
---@field BuffList XBagOrganizeBuff[] @方便遍历移除操作
local XBagOrganizeScopeEntity = XClass(nil, 'XBagOrganizeScopeEntity')

function XBagOrganizeScopeEntity:Ctor(id)
    self.Id = id
end

--region Buff实例相关
function XBagOrganizeScopeEntity:AddBuffRef(buff)
    if self.BuffDict == nil then
        self.BuffDict = {}
    end

    if self.BuffList == nil then
        self.BuffList = {}
    end

    if self.BuffDict[buff] then
        XLog.Error('对实体:'..tostring(self.Id)..' 重复添加buff：'..tostring(buff))
        return
    end
    
    self.BuffDict[buff] = true
    table.insert(self.BuffList, buff)
end

function XBagOrganizeScopeEntity:RemoveBuffRef(buff)
    if XTool.IsTableEmpty(self.BuffDict) or not self.BuffDict[buff] then
        XLog.Error('对实体:'..tostring(self.Id)..' 移除未挂载的buff：'..tostring(buff))
        return
    end

    self.BuffDict[buff] = nil
    
    local isin, index = table.contains(self.BuffList, buff)

    if isin then
        table.remove(self.BuffList, index)
    end
end

--- 检查是否有指定类型的任意Buff
function XBagOrganizeScopeEntity:CheckHasBuffByBuffType(buffType)
    if XTool.IsTableEmpty(self.BuffDict) then
        return false
    end

    for buff, _ in pairs(self.BuffDict) do
        if buff.BuffType == buffType then
            return true
        end
    end
    
    return false
end

--- 外界手动清空该实体身上的所有buff
function XBagOrganizeScopeEntity:RemoveAllBuffEffectByHand()
    if not XTool.IsTableEmpty(self.BuffDict) then
        ---@type XBagOrganizeBuff
        for buff, v in pairs(self.BuffDict) do
            buff:ClearBuffEffect(self)
            buff:Recycle()
        end
        
        self.BuffDict = nil
        self.BuffList = nil
    end
end

--- 尝试清除buff，可指定类型和id。在没有buff或对应buff的情况下该接口不会引发错误
function XBagOrganizeScopeEntity:ClearBuffEffectByTypeOrConfigId(buffType, configId)
    if not XTool.IsTableEmpty(self.BuffList) then
        for i = #self.BuffList, 1, -1 do
            local buff = self.BuffList[i]

            local isSatisfyBuffType = buffType == nil and true or buff.BuffType == buffType
            local isSatisfyConfigId = configId == nil and true or buff.ConfigId == configId
            
            if isSatisfyBuffType and isSatisfyConfigId then
                buff:ClearBuffEffect(self)
                self.BuffDict[buff] = nil
                table.remove(self.BuffList, i)

                buff:Recycle()
            end
        end
    end
end

function XBagOrganizeScopeEntity:GetBuffDataByBuffId(buffId)
    if not XTool.IsTableEmpty(self.BuffList) then
        for i, buff in pairs(self.BuffList) do
            if buff.ConfigId == buffId then
                return buff
            end
        end
    end
end
--endregion


--region buff添加标记相关
function XBagOrganizeScopeEntity:AddTag(tag)
    if self.TagDict == nil then
        self.TagDict = {}
    end

    if self.TagDict[tag] then
        self.TagDict[tag] = self.TagDict[tag] + 1
    else
        self.TagDict[tag] = 1
    end
end

---@param noTips @当不存在标签时忽略报错，用于移除手动添加的tag，手动添加tag没有buff机制限制大
function XBagOrganizeScopeEntity:RemoveTag(tag, noTips)
    if not XTool.IsTableEmpty(self.TagDict) then
        if self.TagDict[tag] then
            self.TagDict[tag] = self.TagDict[tag] - 1

            if self.TagDict[tag] <= 0 then
                self.TagDict[tag] = nil
            end
            
            return
        end
    end

    if not noTips then
        XLog.Error('对实体:'..tostring(self.Id)..' 移除不存在的Tag：'..tostring(tag))
    end
end

function XBagOrganizeScopeEntity:CheckHasTag(tag)
    if XTool.IsTableEmpty(self.TagDict) then
        return false
    end
    
    return XTool.IsNumberValid(self.TagDict[tag])
end

--endregion

return XBagOrganizeScopeEntity
