local XUiGridRpgMakerGameCardMini = XClass(nil, "XUiGridRpgMakerGameCardMini")

local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

--提示说明地图上节点的小图标
function XUiGridRpgMakerGameCardMini:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridRpgMakerGameCardMini:Refresh(blockId, colIndex, blockStatus, mapId)
    local isBlock = blockStatus == XRpgMakerGameConfigs.XRpgMakerGameBlockStatus.Block
    local row = XRpgMakerGameConfigs.GetRpgMakerGameBlockRow(blockId)
    local monsterId = XRpgMakerGameConfigs.GetRpgMakerGameMonsterId(mapId, colIndex, row)
    local isStartPoint = XRpgMakerGameConfigs.IsRpgMakerGameStartPoint(mapId, colIndex, row)
    local isEndPoint = XRpgMakerGameConfigs.IsRpgMakerGameEndPoint(mapId, colIndex, row)
    local triggerId = XRpgMakerGameConfigs.GetRpgMakerGameTriggerId(mapId, colIndex, row)
    local sameXYGapIdList = XRpgMakerGameConfigs.GetRpgMakerGameSameXYGapIdIdList(mapId, colIndex, row)

    --设置移动路线图标
    local isShowMoveLine = XRpgMakerGameConfigs.IsRpgMakerGameHintShowMoveLine(mapId, row, colIndex)
    if isShowMoveLine then
        local moveLineIcon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("MoveLineIcon")
        self.ImageLine:SetRawImage(moveLineIcon)
        self.ImageLine.gameObject:SetActiveEx(true)
    else
        self.ImageLine.gameObject:SetActiveEx(false)
    end

    local icon
    if isBlock then
        icon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("BlockIcon")
    elseif monsterId then
        local monsterType = XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(monsterId)
        icon = XRpgMakerGameConfigs.GetNormalMonsterIcon(monsterType)
    elseif isStartPoint then
        icon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("StartPointIcon")
    elseif isEndPoint then
        icon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("EndPointIcon")
    elseif triggerId then
        local triggerType = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        icon = XRpgMakerGameConfigs.GetTriggerIcon(triggerType)
    end

    --设置缝隙图标列表
    if not XTool.IsTableEmpty(sameXYGapIdList) then
        self:SetGapIcon(sameXYGapIdList)
    end

    if icon then
        self.ImgIcon:SetRawImage(icon)
        self.ImgIcon.gameObject:SetActiveEx(true)
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
    end
end

function XUiGridRpgMakerGameCardMini:SetGapIcon(sameXYGapIdList)
    local icon = XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("GapIcon")
    local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
    local imgIcon
    local direction
    local gapSize = self.ImgIcon.transform.sizeDelta
    local originPos = self.ImgIcon.transform.localPosition
    local directionPos
    local lookRotation

    for i, gapId in ipairs(sameXYGapIdList) do
        direction = XRpgMakerGameConfigs.GetRpgMakerGameGapDirection(gapId)
        imgIcon = CSUnityEngineObjectInstantiate(self.ImgIcon, self.Transform)
        if direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridLeft then
            directionPos = originPos - Vector3(gapSize.x / 2, 0, 0)
        elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridRight then
            directionPos = originPos + Vector3(gapSize.x / 2, 0, 0)
        elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridTop then
            directionPos = originPos + Vector3(0, gapSize.y / 2, 0)
        elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridBottom then
            directionPos = originPos - Vector3(0, gapSize.y / 2, 0)
        end

        if directionPos then
            imgIcon.transform.localPosition = directionPos
            imgIcon.transform.up = originPos - directionPos
        end
        imgIcon:SetRawImage(icon)
        imgIcon.gameObject:SetActiveEx(true)
    end
end

return XUiGridRpgMakerGameCardMini