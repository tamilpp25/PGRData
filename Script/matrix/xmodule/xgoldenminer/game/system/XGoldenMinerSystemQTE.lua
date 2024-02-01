---@class XGoldenMinerSystemQTE:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemQTE = XClass(XEntityControl, "XGoldenMinerSystemQTE")

--region Override
function XGoldenMinerSystemQTE:EnterGame()
    ---QTE触发钩子
    ---@type XGoldenMinerEntityHook
    self._QTEHookEntity = false
    ---QTE触发抓取
    ---@type XGoldenMinerEntityStone
    self._QTEStoneEntity = false
    ---QTE触发钩子缓存
    ---@type XGoldenMinerEntityHook
    self._QTECatchHookEntityList = { }
    ---QTE触发抓取缓存
    ---@type XGoldenMinerEntityStone
    self._QTECatchStoneEntityList = { }
end

function XGoldenMinerSystemQTE:OnUpdate(time)
    self:_UpdateQTE(self._QTEStoneEntity, time)
end

function XGoldenMinerSystemQTE:OnRelease()
    self._QTEHookEntity = nil
    self._QTEStoneEntity = nil
    self._QTECatchHookEntityList = nil
    self._QTECatchStoneEntityList = nil
end
--endregion

--region QTE Update
---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_CheckQTEIsAlive(QTE)
    if not QTE then
        return false
    end
    return QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.ALIVE
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemQTE:_UpdateQTE(stoneEntity, time)
    local QTE = stoneEntity:GetComponentQTE()
    if not QTE then
        return
    end
    if QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.NONE then
        QTE.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.ALIVE
        XMVCA.XGoldenMiner:DebugWarning("QTE开始:GroupId="..QTE.QTEGroupId..",持续时间="..QTE.Time)
    elseif QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.ALIVE then
        self:_UpdateQteAlive(QTE, time)
    elseif QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.WAIT then
        self:_UpdateQteWait(QTE, time)
    elseif QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.BE_DIE then
        self:_UpdateQteBeDie(QTE, time)
    elseif QTE.Status == XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.DIE then
        return
    end
end

---@param QTE XGoldenMinerComponentQTE
---@param time number
function XGoldenMinerSystemQTE:_UpdateQteAlive(QTE, time)
    self:_RefreshQTETime(QTE, time)
    if QTE.CurTime <= 0 then
        QTE.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.BE_DIE
    end
    if QTE.CurClickCount >= QTE.ClickCount then
        QTE.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.BE_DIE
    end
    if QTE.ProgressPanel then
        QTE.ProgressPanel.gameObject:SetActiveEx(true)
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_UpdateQteWait(QTE, time)
    QTE.WaitTime = QTE.WaitTime - time
    if QTE.WaitTime <= 0 then
        QTE.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.ALIVE
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_UpdateQteBeDie(QTE, time)
    QTE.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.DIE
    if QTE.ProgressPanel then
        QTE.ProgressPanel.gameObject:SetActiveEx(false)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.QTE_COMPLETE,
            QTE.QTEIcon and QTE.QTEIcon.transform,
            self._MainControl:GetClientEffectQTEComplete())
    self:QTECrab()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END)
    XMVCA.XGoldenMiner:DebugWarning("QTE结束:GroupId="..QTE.QTEGroupId)
end
--endregion

--region QTE
function XGoldenMinerSystemQTE:ClickQTE()
    if not self._MainControl:IsQTE() then
        return
    end
    local entity = self._QTEStoneEntity
    if not entity then
        return
    end

    local qteComponent = entity:GetComponentQTE()
    if qteComponent and self:_CheckQTEIsAlive(qteComponent) then
        qteComponent.CurClickCount = qteComponent.CurClickCount + 1
        local qteId = self._MainControl:GetCfgQTELevelGroupByCount(qteComponent.QTEGroupId, qteComponent.CurClickCount)
        qteComponent.SpeedRate = self._MainControl:GetCfgQTELevelSpeedRate(qteId)
        self:_RefreshQTETime(qteComponent, self._MainControl:GetCfgQTELevelDownTime(qteId))
        self:_RefreshQTEIcon(qteComponent)
        qteComponent.WaitTime = self._MainControl:GetClientQTEWaitTime()
        if qteComponent.WaitTime > 0 then
            qteComponent.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.WAIT
        end
        if qteComponent.AnimClick and qteComponent.IsCanAnimClick then
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                    XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.QTE_CLICK,
                    qteComponent.QTEIcon and qteComponent.QTEIcon.transform or entity:GetTransform(),
                    self._MainControl:GetClientEffectQTEClick())
            qteComponent.IsCanAnimClick = false
            qteComponent.AnimClick:PlayTimelineAnimation(function()
                qteComponent.IsCanAnimClick = true
            end)
        end
        XMVCA.XGoldenMiner:DebugWarning("QTE点击:ClickCount="..qteComponent.CurClickCount,
                "当前阶段Id:QTEId="..qteId,
                "剩余时间"..qteComponent.Time - qteComponent.CurTime)
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_RefreshQTEIcon(QTE)
    if not QTE.QTEIcon or XTool.UObjIsNil(QTE.QTEIcon) then
        return
    end
    local qteId = self._MainControl:GetCfgQTELevelGroupByCount(QTE.QTEGroupId, QTE.CurClickCount)
    local icon = self._MainControl:GetCfgQTELevelGroupIcon(qteId)
    if string.IsNilOrEmpty(icon) then
        return
    end
    QTE.QTEIcon:SetRawImage(icon)
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_RefreshQTETime(QTE, time)
    QTE.CurTime = QTE.CurTime - time
    if not QTE.ProgressPanel or XTool.UObjIsNil(QTE.ProgressPanel) then
        return
    end
    QTE.ProgressFillImage.fillAmount = QTE.CurTime / QTE.Time
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
---@return boolean isStart
function XGoldenMinerSystemQTE:QTEStart(hookEntity, stoneEntity, isInQTE)
    if isInQTE then
        if self._QTEHookEntity and self._QTEHookEntity ~= hookEntity
                and self._QTEStoneEntity and self._QTEStoneEntity ~= stoneEntity
                and not table.indexof(self._QTECatchHookEntityList, hookEntity)
                and not table.indexof(self._QTECatchStoneEntityList, stoneEntity)
        then
            self._QTECatchHookEntityList[#self._QTECatchHookEntityList + 1] = hookEntity
            self._QTECatchStoneEntityList[#self._QTECatchStoneEntityList + 1] = stoneEntity
        end
        return false
    end
    self._QTEHookEntity = hookEntity
    self._QTEStoneEntity = stoneEntity
    return true
end

function XGoldenMinerSystemQTE:QTECrab()
    if not self._MainControl:IsQTE() then
        return
    end

    local QTE = self._QTEStoneEntity:GetComponentQTE()
    local qteId = self._MainControl:GetCfgQTELevelGroupByCount(QTE.QTEGroupId, QTE.CurClickCount)
    local params = self._MainControl:GetCfgQTELevelGroupParams(qteId)
    local type = self._MainControl:GetCfgQTELevelGroupType(qteId)
    if type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.SCORE then
        QTE.AddScore = params[1]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.ITEM then
        QTE.AddItemId = params[1]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.BUFF then
        QTE.AddBuff = params[1]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.SCORE_AND_BUFF then
        QTE.AddScore = params[1]
        QTE.AddBuff = params[2]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.SCORE_AND_ITEM then
        QTE.AddScore = params[1]
        QTE.AddItemId = params[2]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.BUFF_AND_ITEM then
        QTE.AddBuff = params[1]
        QTE.AddItemId = params[2]
    elseif type == XEnumConst.GOLDEN_MINER.QTE_GROUP_TYPE.ALL then
        QTE.AddScore = params[1]
        QTE.AddBuff = params[2]
        QTE.AddItemId = params[3]
    end

    if self._QTEHookEntity then
        -- 状态不对过滤
        if self._QTEHookEntity:GetComponentHook():CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.MAGNETIC) 
                or self._QTEHookEntity:GetComponentHook():CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC)
        then
            self._MainControl:HandleHookGrabStone(self._QTEHookEntity, self._QTEStoneEntity)
        else
            self._MainControl:HookGrab(self._QTEHookEntity, self._QTEStoneEntity)
        end
    end
    self._QTEHookEntity = false
    self._QTEStoneEntity = false
    self._MainControl:QTEResume()
    self:_QTECheck()
end

function XGoldenMinerSystemQTE:_QTECheck()
    if XTool.IsTableEmpty(self._QTECatchHookEntityList) then
        return
    end
    local hookEntity = self._QTECatchHookEntityList[1]
    local stoneEntity = self._QTECatchStoneEntityList[1]
    local newHookList = {}
    local newStoneList = {}
    for i = 2, #self._QTECatchHookEntityList do
        newHookList[#newHookList + 1] = self._QTECatchHookEntityList[i]
        newStoneList[#newStoneList + 1] = self._QTECatchStoneEntityList[i]
    end
    self._QTECatchHookEntityList = newHookList
    self._QTECatchStoneEntityList = newStoneList
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, hookEntity, stoneEntity)
end
--endregion

return XGoldenMinerSystemQTE

