--- 2048玩法统筹表现层行为序列的组件
---@class XUiComGame2048MapAction: XUiNode
---@field Parent XUiPanelGame2048Map
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiComGame2048MapAction = XClass(XUiNode, 'XUiComGame2048MapAction')

function XUiComGame2048MapAction:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.EffectThunder.gameObject:SetActiveEx(false)

    self:InitActionEvents()
    -- 常量读取
    self._ConstThunderTime = self._Control:GetClientConfigNum('ThunderTime')
    self._ConstThunderBeforeWaitTime = self._Control:GetClientConfigNum('ThunderBeforeWaitTime')
end

function XUiComGame2048MapAction:OnDisable()
    self:UnDoAllAnimation()
end

function XUiComGame2048MapAction:InitActionEvents()
    self._ActionEventMap = {
        [XMVCA.XGame2048.EnumConst.ActionType.NormalMove] = handler(self, self.GridMoveAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalMerge] = handler(self, self.GridMergeAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalDispel] = handler(self, self.GridDispelAction),
        [XMVCA.XGame2048.EnumConst.ActionType.RockReduce] = handler(self, self.GridRockReduceAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalReduce] = handler(self, self.GridNormalReduceAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NewBlockBorn] = handler(self, self.GridNewBornAction),
        [XMVCA.XGame2048.EnumConst.ActionType.RockShake] = handler(self, self.GridRockShakeAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUp] = handler(self, self.FeverLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalLevelUp] = handler(self, self.NormalLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.TransferLevelUp] = handler(self, self.TransferLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.ICELevelUp] = handler(self, self.ICELevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverUpLevelUp] = handler(self, self.FeverUpLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck] = handler(self, self.FeverLevelUpCheckAction),
    }
    
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_NOTIFY_ACTION_EVENT, self.OnActionEventNotify, self)
end


function XUiComGame2048MapAction:OnActionEventNotify(actionType, action)
    if self._ActionEventMap[actionType] then
        self._ActionEventMap[actionType](action)
    end
end

--region -------------------- 行为动画 -------------------->>>

---@param action XGame2048Action
function XUiComGame2048MapAction:GridMoveAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local fromIndex = action.MoveFromX + (action.MoveFromY - 1) * self._GameControl:GetWidth()
    local toIndex = action.MoveToX + (action.MoveToY - 1) * self._GameControl:GetWidth()

    if uiGrid then
        local fromBg = self.Parent:GetShowedUiGridByIndex(fromIndex)
        local toBg = self.Parent:GetShowedUiGridByIndex(toIndex)
        
        uiGrid.ActionCom:DoMove(fromBg.Transform, toBg.Transform, function()
            uiGrid:SetNormalizePos(action.MoveToX, action.MoveToY)
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridMoveSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridMergeAction(action)
    ---@type XUiGridGame2048Grid
    local upgradeGrid = self.Parent:GetShowedUiGridByUid(action.GridUidB)
    local disappearGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if action.GridUidB == action.GridUidA then
        XLog.Error("同一个方块不可与自己合成")
        self._GameControl.ActionsControl:EndAction(action)
        return
    end

    if disappearGrid then
        if action.GridUidA ~= disappearGrid.Uid then
            XLog.Error("行为对象里记录的Uid和表现层UI缓存的Uid不一致", action.GridUidA, disappearGrid.Uid)
        end
        
        self.Parent:ReturnUiGridToPool(disappearGrid)
    end

    ---@type XGame2048Grid
    local gridData = nil

    -- 如果升级的方块类型发生了变化，需要回收并按照新的类型获取UI
    if upgradeGrid then
        gridData = self._GameControl:GetGridEntityByUid(action.GridUidB)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end

        if upgradeGrid:GetGridType() ~= gridData:GetGridType() then
            self.Parent:ReturnUiGridToPool(upgradeGrid)
            self.Parent:RefreshNewGrid(gridData)
            upgradeGrid = self.Parent:GetShowedUiGridByUid(action.GridUidB)
        end
    end

    if upgradeGrid then
        if gridData == nil then
            gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

            if action.TempGridData then
                action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
                gridData = action.TempGridData
            end
        end
        
        if gridData then
            local blockId = gridData.Id
            
            upgradeGrid:RefreshData(gridData)

            self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_DATA_REFRESH)

            upgradeGrid.ActionCom:DoMerge(function()
                -- 方块合成后需检查盘面是否升级，并做相应的处理
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(blockId)
                self._GameControl.BoardShowControl:OnGridMergeEvent(blockId)
                
                self._GameControl.ActionsControl:EndAction(action)
            end, true)
        else
            -- 如果没有数据，则是在连续合成中被消除了，被消除的由DispelAction进行回收
            -- 这里仅刷新UI显示
            if XTool.IsNumberValid(action.GridIdB) then
                upgradeGrid:SetShow(action.GridIdB)
                upgradeGrid.ActionCom:DoMerge(function()
                    self._GameControl.ActionsControl:EndAction(action)
                end)
            else
                self._GameControl.ActionsControl:EndAction(action)
            end

        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridDispelAction(action)
    local dispelGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if dispelGrid then
        dispelGrid.ActionCom:DoDispel(function()
            if action.GridUidA ~= dispelGrid.Uid then
                XLog.Error("行为对象里记录的Uid和表现层UI缓存的Uid不一致", action.GridUidA, dispelGrid.Uid)
            end
            
            self.Parent:ReturnUiGridToPool(dispelGrid)
            
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridRockShakeAction(action)
    local rock = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if rock then
        -- 播放石头撞击动画
        rock.ActionCom:DoShake(function()
            -- 刷新显示
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridRockReduceAction(action)
    local rock = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local rockGrid = self._GameControl:GetGridEntityByUid(action.GridUidA)
    if not rockGrid then
        
    else
        -- 刷新显示
        rock:RefreshData(rockGrid)
    end
    self._GameControl.ActionsControl:EndAction(action)
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridNormalReduceAction(action)
    local block = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local blockGrid = self._GameControl:GetGridEntityByUid(action.GridUidA)
    -- 刷新显示
    block:RefreshData(blockGrid)

    self._GameControl.ActionsControl:EndAction(action)
end

---@param action XGame2048Action
function XUiComGame2048MapAction:GridNewBornAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        uiGrid.ActionCom:DoBorn(function()
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridBornSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:NormalLevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:TransferLevelUpAction(action)
    -- 传导方块被传导升级后，类型会发生变化，需要替换UI
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end

            if uiGrid then
                uiGrid:RefreshData(gridData)
                uiGrid.ActionCom:DoMerge(function()
                    self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                    self._GameControl.ActionsControl:EndAction(action)
                end, true, action.MergeEffectType)
            else
                self._GameControl.ActionsControl:EndAction(action)
            end
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:ICELevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end
            
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:FeverUpLevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048Action
function XUiComGame2048MapAction:FeverLevelUpCheckAction(action)
    self._GameControl:DoFeverLevelUp()
    self._GameControl.ActionsControl:EndAction(action)
end

--endregion <<<---------------------------------------------

---@param action XGame2048Action
function XUiComGame2048MapAction:FeverLevelUpAction(action)
    self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_LEVELUP)
    XLuaUiManager.OpenWithCloseCallback('UiGame2048ToastLvUp', function()
        self._GameControl.ActionsControl:EndAction(action)
    end)
end

--region -------------------- 特效动画 -------------------->>>
function XUiComGame2048MapAction:UnDoAllAnimation()
    
end
--endregion <<<---------------------------------------------

--region 棋盘音效
function XUiComGame2048MapAction:HideAllSFX()
    self.SFX_GridUp.gameObject:SetActiveEx(false)
    self.SFX_GridMove.gameObject:SetActiveEx(false)
    self.SFX_GridBorn.gameObject:SetActiveEx(false)
end

function XUiComGame2048MapAction:ResetSFXLock()
    self._GridUpSFXPlaying = false
    self._GridMoveSFXPlaying = false
    self._GridBornSFXPlaying = false

    self:HideAllSFX()
end

function XUiComGame2048MapAction:EnableGridUpSFX()
    if not self._GridUpSFXPlaying then
        self._GridUpSFXPlaying = true
        self.SFX_GridUp.gameObject:SetActiveEx(true)
    end
end

function XUiComGame2048MapAction:EnableGridMoveSFX()
    if not self._GridMoveSFXPlaying then
        self._GridMoveSFXPlaying = true
        self.SFX_GridMove.gameObject:SetActiveEx(true)
    end
end

function XUiComGame2048MapAction:EnableGridBornSFX()
    if not self._GridBornSFXPlaying then
        self._GridBornSFXPlaying = true
        self.SFX_GridBorn.gameObject:SetActiveEx(true)
    end
end
--endregion

return XUiComGame2048MapAction
