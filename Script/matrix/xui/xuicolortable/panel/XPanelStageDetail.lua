-- Grid - 效果描述
--===============================================================================
local XGridEvent  = XClass(nil, "XGridEvent")

function XGridEvent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XGridEvent:Refresh(eventId)
    self.RImgBuffIcon:SetRawImage(XColorTableConfigs.GetEventSmallIcon(eventId))
    self.TxtBuffName.text = XColorTableConfigs.GetEventName(eventId)
    self.TxtBuffDetails.text = XColorTableConfigs.GetEventDesc(eventId)
    self.TxtTimeDetails.gameObject:SetActiveEx(XDataCenter.ColorTableManager.GetGameManager():CheckEventIsNextRound(eventId))
    self:SetActive(true)
end

function XGridEvent:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

--===============================================================================


-- 关卡详情
local XPanelStageDetail = XClass(nil, "XPanelStageDetail")

function XPanelStageDetail:Ctor(root, ui, stageId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    self.CTStageId = stageId

    self:_InitUiObject()
end

-- 遭遇事件显示
function XPanelStageDetail:RefreshEventBuff(eventIdList)
    for index, eventId in ipairs(eventIdList) do
        if not self.EventGridList[index] then
            self.EventGridList[index] = XGridEvent.New(XUiHelper.Instantiate(self.GridBuff, self.PanelBuff))
        end
        self.EventGridList[index]:Refresh(eventId)
    end

    for i = #eventIdList + 1, #self.EventGridList, 1 do
        self.EventGridList[i]:SetActive(false)
    end
end

function XPanelStageDetail:OpenDetail(callback)
    if self.IsOpen then
        return
    end
    self.IsOpen = true
    self.PanelEffect.gameObject:SetActiveEx(true)
    self.PanelEffectExit.gameObject:SetActiveEx(false)
    if callback then callback() end
end

function XPanelStageDetail:CloseDetail(callback)
    if not self.IsOpen then
        return
    end
    self.IsOpen = false
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffectExit.gameObject:SetActiveEx(true)
    if callback then callback() end
end

function XPanelStageDetail:GetIsOpen()
    return self.IsOpen
end

function XPanelStageDetail:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_REFRESHEVENT, self.RefreshEventBuff, self)
end

function XPanelStageDetail:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_REFRESHEVENT, self.RefreshEventBuff, self)
end

-- private
----------------------------------------------------------------

function XPanelStageDetail:_InitUiObject()
    XTool.InitUiObject(self)

    self.IsOpen = false

    self.PanelEffect = self.Transform:Find("PanelEffect")
    self.PanelEffectExit = self.Transform:Find("PanelEffectExit")
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffectExit.gameObject:SetActiveEx(false)
    self.RImgWinIcon1.gameObject:SetActiveEx(false)
    self.TxtDetailsWin1.gameObject:SetActiveEx(false)
    self.RImgWinIcon2.gameObject:SetActiveEx(false)
    self.TxtDetailsWin2.gameObject:SetActiveEx(false)
    self.ImgWinBg1.gameObject:SetActiveEx(false)
    self.ImgWinBg2.gameObject:SetActiveEx(false)
    self.PanelStage.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)

    self.WinConditionIcon = {
        self.RImgWinIcon1,
        self.RImgWinIcon2,
    }
    self.WinConditionDesc = {
        self.TxtDetailsWin1,
        self.TxtDetailsWin2,
    }
    self.WinConditionBg = {
        self.ImgWinBg1,
        self.ImgWinBg2,
    }

    self.EventGridList = {}

    self:_RefreshWinCondition()
    self:_RefreshStageBuff()
end

-- 胜利条件展示
function XPanelStageDetail:_RefreshWinCondition()
    local winConditionIds = {}
    local normalWinConditionId = XColorTableConfigs.GetStageNormalWinConditionId(self.CTStageId)
    local specialWinConditionId = XColorTableConfigs.GetStageSpecialWinConditionId(self.CTStageId)
    if XTool.IsNumberValid(normalWinConditionId) then table.insert(winConditionIds, normalWinConditionId) end
    if XTool.IsNumberValid(specialWinConditionId) then table.insert(winConditionIds, specialWinConditionId) end

    for index, conditionId in pairs(winConditionIds) do
        self.WinConditionIcon[index]:SetRawImage(XColorTableConfigs.GetWinConditionIcon(conditionId))
        self.WinConditionDesc[index].text = XColorTableConfigs.GetWinConditionName(conditionId)
        self.WinConditionIcon[index].gameObject:SetActiveEx(true)
        self.WinConditionDesc[index].gameObject:SetActiveEx(true)
        self.WinConditionBg[index].gameObject:SetActiveEx(true)
    end
end

-- 关卡效果展示
function XPanelStageDetail:_RefreshStageBuff()
    local gameData = XDataCenter.ColorTableManager.GetGameManager():GetGameData()
    if gameData:CheckIsGuideStage() then
        self.PanelStage.gameObject:SetActiveEx(false)
        return
    end
    local stageEffectId = XColorTableConfigs.GetStageStageEffectId(self.CTStageId)
    if XTool.IsNumberValid(stageEffectId) then
        self.PanelStage.gameObject:SetActiveEx(true)
        self.RImgStageIcon:SetRawImage(XColorTableConfigs.GetStageEffectIcon(stageEffectId))
        self.TxtStageName.text = XColorTableConfigs.GetStageEffectName(stageEffectId)
        self.TxtStageDetails.text = XColorTableConfigs.GetStageEffectDesc(stageEffectId)
    end
end

----------------------------------------------------------------

return XPanelStageDetail