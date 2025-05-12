--- 2048玩法分管动画序列的子控制器
---@class XGame2048ActionsControl: XControl
---@field private _MainControl XGame2048GameControl
---@field private _Model XGame2048Model
---@field private _ActionEntityPool XPool
local XGame2048ActionsControl = XClass(XControl, 'XGame2048ActionsControl')
local XGame2048Action = require('XModule/XGame2048/InGame/Entity/XGame2048Action')

function XGame2048ActionsControl:OnInit()
    self._ActionEntityPool = XPool.New(function()
        return XGame2048Action.New()
    end,
    function(action)
        action:ResetData()
    end, false)
end

function XGame2048ActionsControl:OnRelease()

end

function XGame2048ActionsControl:InitActions()
    -- 回收
    if not XTool.IsTableEmpty(self._ActionList) then
        for priority, actionGroup in pairs(self._ActionList) do
            if not XTool.IsTableEmpty(actionGroup) then
                for i, v in pairs(actionGroup) do
                    self._ActionEntityPool:ReturnItemToPool(v)
                end
            end
        end
    end

    -- 重置
    self._ActionList = {}

    self._ActionPlaying = false
end

function XGame2048ActionsControl:GetIsActionPlaying()
    return self._ActionPlaying
end

function XGame2048ActionsControl:StartActionList(cb)
    if cb then
        self._ActionCallBack = cb
    end

    if not XTool.IsTableEmpty(self._ActionList) then
        self._ActionPlaying = true
        -- 需注意这里priority的映射中，value是连续的，如果枚举调整了，这里也要修改逻辑
        for i = 1, XTool.GetTableCount(XMVCA.XGame2048.EnumConst.ActionPriority) do
            local actionGroup = self._ActionList[i]
            -- 按优先级逐一查找，如果遇到了存在的行为组，则执行
            if not XTool.IsTableEmpty(actionGroup) then

                -- 记录该行为组的行为数目
                self._NoOverActionCount = XTool.GetTableCount(self._ActionList[i])

                -- 清空该行为组
                self._ActionList[i] = nil

                ---@param v XGame2048Action
                for i2, v in pairs(actionGroup) do
                    self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_NOTIFY_ACTION_EVENT, v:GetActionType(), v)
                end
                return
            end
        end
    else
        -- 当没有可以执行的行为时执行回调
        if self._ActionCallBack then
            local cb = self._ActionCallBack
            self._ActionCallBack = nil

            cb()
        end
        self._ActionPlaying = false
    end
end

function XGame2048ActionsControl:EndAction(action)
    if action.EventId ~= nil then
        self._MainControl:DispatchEvent(action.EventId, table.unpack(action.EventArgs))
    end

    --回收
    if action.TempGridData then
        self._MainControl:ReturnGridDataToPool(action.TempGridData)
        action.TempGridData = nil
    end
    
    self._ActionEntityPool:ReturnItemToPool(action)

    self._NoOverActionCount = self._NoOverActionCount - 1

    if self._NoOverActionCount <= 0 then
        self:StartActionList()
    end
end

---@param action XGame2048Action
function XGame2048ActionsControl:InsertActionToList(action)
    local type = action:GetActionType()
    local priority = XMVCA.XGame2048.EnumConst.ActionPriority[type]
    local noInsert = false

    if self._ActionList[priority] == nil then
        self._ActionList[priority] = {}
    end

    -- 在一次执行中，一个格子在一个方向上可能断断续续走了几步，需要将这几步合并为一步
    if type == XMVCA.XGame2048.EnumConst.ActionType.NormalMove and not XTool.IsTableEmpty(self._ActionList[priority]) then
        local mergeSameAction = false
        ---@param v XGame2048Action
        for i, v in pairs(self._ActionList[priority]) do
            if v.GridUidA == action.GridUidA then
                -- 后续的移动行为，目的地覆盖旧的
                v:SetMoveAction(v.GridUidA, v.MoveFromX, v.MoveFromY, action.MoveToX, action.MoveToY, action.GridUidB and action.GridUidB or v.GridUidB)
                -- 关联相同移动对象的行为
                mergeSameAction = true
                break
            end
        end

        if mergeSameAction then
            self._ActionEntityPool:ReturnItemToPool(action)
            noInsert = true
        end
    end

    if not noInsert then
        table.insert(self._ActionList[priority], action)
    end

    --处理具有关联性的移动
    if type == XMVCA.XGame2048.EnumConst.ActionType.NormalMove and not XTool.IsTableEmpty(self._ActionList[priority]) then
        -- 先构建gridUid-moveaction映射表
        local uidToAction = {}
        ---@param v XGame2048Action
        for i, v in pairs(self._ActionList[priority]) do
            uidToAction[v.GridUidA] = v
        end

        --再遍历将action的目标位置同步为follow的目标位置
        local beginIndex = 1
        local endIndex = #self._ActionList[priority]

        for i = beginIndex, endIndex do
            local tmpAction = self._ActionList[priority][i]
            if XTool.IsNumberValid(tmpAction.GridUidB) and uidToAction[tmpAction.GridUidB] then
                local followAction = uidToAction[tmpAction.GridUidB]
                tmpAction:SetMoveAction(tmpAction.GridUidA, tmpAction.MoveFromX, tmpAction.MoveFromY, followAction.MoveToX, followAction.MoveToY, tmpAction.GridUidB)
            end
        end
    end
end

---@param followGridUid @当多个方块连续合成时，为了实现视效上多个方块一起移动到最终合成的位置，而需要记录一个followUid，当更新合并移动位置时，followUid相同的做相同的合并处理
function XGame2048ActionsControl:AddMoveAction(moveGridUid, fromx, fromy, tox, toy, followGridUid)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalMove)
    action:SetMoveAction(moveGridUid, fromx, fromy, tox, toy, followGridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalMerge)
    action:SetMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    
    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(mergeToUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddDispelAction(bombGridUid)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalDispel)
    action:SetDispelAction(bombGridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddRockReduceAction(rockUid)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.RockReduce)
    action:SetReduceAction(rockUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddRockShakeAction(rockUid)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.RockShake)
    action:SetReduceAction(rockUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNormalReduceAction(normalUid)
    ---@type XGame2048Action
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalReduce)
    action:SetReduceAction(normalUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNewBornAction(gridUid)
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NewBlockBorn)
    action:SetNewBornAction(gridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverLevelUpAction()
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUp)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNormalLevelUpAction(normalUid, mergeEffectType)
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalLevelUp)
    action:SetLevelUpAction(normalUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(normalUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddTransferLevelUpAction(transferUid, mergeEffectType)
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.TransferLevelUp)
    action:SetLevelUpAction(transferUid)
    action:SetMergeEffectType(mergeEffectType)
    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(transferUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddICELevelUpAction(iceUid, mergeEffectType)
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.ICELevelUp)
    action:SetLevelUpAction(iceUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(iceUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverUpLevelUpAction(feverUpUid, mergeEffectType)
    local action = self._ActionEntityPool:GetItemFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverUpLevelUp)
    action:SetLevelUpAction(feverUpUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(feverUpUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverLevelUpCheckAction(gridId)
    -- 同一时期最多只能有一个检查
    local priority = XMVCA.XGame2048.EnumConst.ActionPriority[XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck]

    if XTool.IsTableEmpty(self._ActionList[priority]) and self._MainControl:CheckFerverLevelUp(gridId) then
        if self._ActionList[priority] == nil then
            self._ActionList[priority] = {}
        end
        
        local action = self._ActionEntityPool:GetItemFromPool()
        action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck)
        self:InsertActionToList(action)
        return action
    end
end

function XGame2048ActionsControl:_GetCloneTempGridData(gridUid)
    -- 获取数据
    local gridData = self._MainControl:GetGridEntityByUid(gridUid)

    if gridData then
        -- 克隆临时对象
        ---@type XGame2048Grid
        local tmpGridData = self._MainControl:GetGridDataInPool()
        tmpGridData:SetNewConfig(gridData:GetConfig(), gridData:GetTypeCfg())
        tmpGridData.Uid = gridData.Uid
        tmpGridData:SetExValue(gridData:GetExValue())
        tmpGridData:SetMoveLock(gridData:GetIsMoveLock())
        tmpGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
        
        return tmpGridData
    end
    
    return nil
end

return XGame2048ActionsControl