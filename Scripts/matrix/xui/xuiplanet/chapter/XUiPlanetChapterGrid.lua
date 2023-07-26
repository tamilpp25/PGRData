---@class XUiPlanetChapterRewardItem
local XUiPlanetChapterRewardItem = XClass(XUiGridCommon, "XUiPlanetChapterRewardItem")

function XUiPlanetChapterRewardItem:Ctor(rootUi, ui)
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "Item/BtnClick", "Button")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "Item/RImgItem", "RawImage")
    self.RImgItemMove = XUiHelper.TryGetComponent(self.Transform, "Item/RImgItemMove")
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "Item/ImgQuality", "Image")
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "Item/Effect")
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end

function XUiPlanetChapterRewardItem:RefreshIsFinish(isFinish)
    self.RImgItemMove.gameObject:SetActiveEx(isFinish)
end


--=======================================================================================
---@class XUiPlanetChapterGrid
local XUiPlanetChapterGrid = XClass(nil, "XUiPlanetChapterGrid")

function XUiPlanetChapterGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridRewardDir = {}
    XTool.InitUiObject(self)

    self:AddBtnClickListener()
end


--region Ui
function XUiPlanetChapterGrid:Refresh(chapter)
    self.ChapterId = chapter
    local titleIcon = XPlanetStageConfigs.GetChapterTitleIconUrl(self.ChapterId)
    local rewards, isFinishDir = XDataCenter.PlanetManager.GetChapterRewardRecord(self.ChapterId)

    self:RefreshLock()

    if not string.IsNilOrEmpty(titleIcon) then
        self.RawImage:SetRawImage(titleIcon)
    end

    if XTool.IsTableEmpty(rewards) then
        self.PanelItem.gameObject:SetActiveEx(false)
        return
    end
    for index, item in ipairs(rewards) do
        if XTool.IsTableEmpty(self.GridRewardDir[index]) then
            local ui = XUiHelper.Instantiate(self.GridItem, self.PanelItem)
            self.GridRewardDir[index] = XUiPlanetChapterRewardItem.New(ui)
        end
        self.GridRewardDir[index]:Refresh(item)
        self.GridRewardDir[index]:RefreshIsFinish(isFinishDir[index])
    end
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPlanetChapterGrid:RefreshLock()
    local _, playDir = XDataCenter.PlanetManager.CheckChapterUnlockRedPoint()
    local isNeedPlay = playDir[self.ChapterId]
    self.PanelItem.gameObject:SetActiveEx(self:IsOpen() and self:IsPassPreStage() and not isNeedPlay)
    self.RawImage.gameObject:SetActiveEx(self:IsOpen() and self:IsPassPreStage() and not isNeedPlay)
    self.PanelLock.gameObject:SetActiveEx(not self:IsOpen() or not self:IsPassPreStage())
    self.RImgLock.gameObject:SetActiveEx(self:IsOpen() and not self:IsPassPreStage())
    self.RImgTime.gameObject:SetActiveEx(not self:IsOpen())
    if not self:IsOpen() then
        local startTime = XFunctionManager.GetStartTimeByTimeId(XPlanetStageConfigs.GetChapterOpenTimeId(self.ChapterId))
        local nowTime = XTime.GetServerNowTimestamp()
        self.TxtLock.text = XUiHelper.GetText("PivotCombatLockTimeTxt", XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY))
        if not self.LockTimer then
            self:StartRefreshLock()
        end
    else
        self:StopRefreshLock()
    end
end

function XUiPlanetChapterGrid:StartRefreshLock()
    self.LockTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopRefreshLock()
            return
        end
        self:RefreshLock()
    end, XScheduleManager.SECOND, 0)
end

function XUiPlanetChapterGrid:StopRefreshLock()
    if self.LockTimer then
        XScheduleManager.UnSchedule(self.LockTimer)
    end
    self.LockTimer = nil
end

function XUiPlanetChapterGrid:IsOpen()
    return XDataCenter.PlanetManager.GetViewModel():CheckChapterIsInTime(self.ChapterId)
end

function XUiPlanetChapterGrid:IsPassPreStage()
    return XDataCenter.PlanetManager.GetViewModel():CheckChapterPreStageIsPass(self.ChapterId)
end

function XUiPlanetChapterGrid:SetPosition(localPosition)
    if self.Transform.localPosition.x == localPosition.x and self.Transform.localPosition.x == localPosition.y then
        return
    end
    self.Transform.localPosition = Vector3(localPosition.x, localPosition.y, 0)
end
--endregion


--region 按钮绑定
function XUiPlanetChapterGrid:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnClick)
end

function XUiPlanetChapterGrid:OnBtnClick()
    if not self:IsOpen() then
        XUiManager.TipErrorWithKey("PlanetRunningChapterNoOpen")
        return
    end
    if not self:IsPassPreStage() then
        local stageName = XPlanetStageConfigs.GetStageFullName(XPlanetStageConfigs.GetChapterPreStageId(self.ChapterId))
        XUiManager.TipError(XUiHelper.GetText("PlanetRunningTalentCardLock", stageName))
        return
    end
    XLuaUiManager.Open("UiPlanetChapterChoice", self.ChapterId)
end
--endregion

return XUiPlanetChapterGrid