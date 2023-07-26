---@class XGoldenMinerSystemQTE
local XGoldenMinerSystemQTE = XClass(nil, "XGoldenMinerSystemQTE")

---@param game XGoldenMinerGame
function XGoldenMinerSystemQTE:Update(game, time)
    if not game:IsQTE() then
        return
    end
    self:UpdateQTE(game.QTEStoneEntity, time)
end

--region QTE Update
---@param QTE XGoldenMinerComponentQTE
---@param transform UnityEngine.Transform
function XGoldenMinerSystemQTE:InitQTE(QTE, transform)
    QTE.CurTime = QTE.Time
    QTE.ClickCount = XGoldenMinerConfigs.GetQTELevelGroupMaxClickCount(QTE.QTEGroupId)
    QTE.CurClickCount = 0
    QTE.QTEIcon = XUiHelper.TryGetComponent(transform, "Show", "RawImage")
    QTE.AnimClick = XUiHelper.TryGetComponent(transform, "AnimClick")

    if transform.anchoredPosition.x > CS.UnityEngine.Screen.width / 2 then
        QTE.ProgressPanel = XUiHelper.TryGetComponent(transform, "Panel01")
    else
        QTE.ProgressPanel = XUiHelper.TryGetComponent(transform, "Panel02")
    end
    if QTE.ProgressPanel then
        QTE.ProgressFillImage = XUiHelper.TryGetComponent(QTE.ProgressPanel, "ImgUiGoldenMinerJD01", "Image")
        QTE.ProgressPanel.gameObject:SetActiveEx(false)
    end
    self:_RefreshQTEIcon(QTE)
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:CheckQTEIsAlive(QTE)
    if not QTE then
        return false
    end
    return QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.ALIVE
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemQTE:UpdateQTE(stoneEntity, time)
    if not stoneEntity.QTE then
        return
    end
    local QTE = stoneEntity.QTE
    if QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.NONE then
        QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.ALIVE
        --XGoldenMinerConfigs.DebugLog("QTE开始:GroupId="..QTE.QTEGroupId..",持续时间="..QTE.Time)
    elseif QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.ALIVE then
        self:_UpdateQteAlive(QTE, time)
    elseif QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.WAIT then
        self:_UpdateQteWait(QTE, time)
    elseif QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.BE_DIE then
        self:_UpdateQteBeDie(QTE, time)
    elseif QTE.Status == XGoldenMinerConfigs.GAME_QTE_STATUS.DIE then
        return
    end
end

---@param QTE XGoldenMinerComponentQTE
---@param time number
function XGoldenMinerSystemQTE:_UpdateQteAlive(QTE, time)
    self:_RefreshQTETime(QTE, time)
    if QTE.CurTime <= 0 then
        QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.BE_DIE
    end
    if QTE.CurClickCount >= QTE.ClickCount then
        QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.BE_DIE
    end
    if QTE.ProgressPanel then
        QTE.ProgressPanel.gameObject:SetActiveEx(true)
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_UpdateQteWait(QTE, time)
    QTE.WaitTime = QTE.WaitTime - time
    if QTE.WaitTime <= 0 then
        QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.ALIVE
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_UpdateQteBeDie(QTE, time)
    QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.DIE
    if QTE.ProgressPanel then
        QTE.ProgressPanel.gameObject:SetActiveEx(false)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XGoldenMinerConfigs.GAME_EFFECT_TYPE.QTE_COMPLETE,
            QTE.QTEIcon and QTE.QTEIcon.transform,
            XGoldenMinerConfigs.GetEffectPomegranateComplete())
    --XGoldenMinerConfigs.DebugLog("QTE结束:GroupId="..QTE.QTEGroupId)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END)
end
--endregion

--region QTE
---@param game XGoldenMinerGame
function XGoldenMinerSystemQTE:ClickQTE(game)
    if not game:IsQTE() then
        return
    end
    local entity = game.QTEStoneEntity
    if not entity then
        return
    end

    if entity.QTE and self:CheckQTEIsAlive(entity.QTE) then
        entity.QTE.CurClickCount = entity.QTE.CurClickCount + 1
        local qteId = XGoldenMinerConfigs.GetQTELevelGroupByCount(entity.QTE.QTEGroupId, entity.QTE.CurClickCount)
        entity.QTE.SpeedRate = XGoldenMinerConfigs.GetQTELevelSpeedRate(qteId)
        self:_RefreshQTETime(entity.QTE, XGoldenMinerConfigs.GetQTELevelDownTime(qteId))
        self:_RefreshQTEIcon(entity.QTE)
        entity.QTE.WaitTime = XGoldenMinerConfigs.GetQTEWaitTime()
        if entity.QTE.WaitTime > 0 then
            entity.QTE.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.WAIT
        end
        if entity.QTE.AnimClick and entity.QTE.IsCanAnimClick then
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                    XGoldenMinerConfigs.GAME_EFFECT_TYPE.QTE_CLICK,
                    entity.QTE.QTEIcon and entity.QTE.QTEIcon.transform or entity.Stone.Transform,
                    XGoldenMinerConfigs.GetEffectPomegranateClick())
            entity.QTE.IsCanAnimClick = false
            entity.QTE.AnimClick:PlayTimelineAnimation(function()
                entity.QTE.IsCanAnimClick = true
            end)
        end
        --XGoldenMinerConfigs.DebugLog("QTE点击:ClickCount="..entity.QTE.CurClickCount)
        --XGoldenMinerConfigs.DebugLog("当前阶段Id:QTEId="..qteId)
        --XGoldenMinerConfigs.DebugLog("剩余时间"..entity.QTE.Time - entity.QTE.CurTime)
    end
end

---@param QTE XGoldenMinerComponentQTE
function XGoldenMinerSystemQTE:_RefreshQTEIcon(QTE)
    if not QTE.QTEIcon or XTool.UObjIsNil(QTE.QTEIcon) then
        return
    end
    local qteId = XGoldenMinerConfigs.GetQTELevelGroupByCount(QTE.QTEGroupId, QTE.CurClickCount)
    local icon = XGoldenMinerConfigs.GetQTELevelGroupIcon(qteId)
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
--endregion

return XGoldenMinerSystemQTE

