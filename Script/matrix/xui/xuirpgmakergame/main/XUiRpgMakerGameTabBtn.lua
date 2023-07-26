local XUiRpgMakerGameTabBtn = XClass(nil, "XUiRpgMakerGameTabBtn")

local ButtonStateDisable = CS.UiButtonState.Disable

function XUiRpgMakerGameTabBtn:Ctor(ui, tabBtnIndex)
    self.BtnPlotTab = ui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.TabBtnIndex = tabBtnIndex
end

function XUiRpgMakerGameTabBtn:Init(chapterId)
    self.ChapterId = chapterId
    local bg = XRpgMakerGameConfigs.GetRpgMakerGameChapterTagBtnBG(chapterId)
    local name = XRpgMakerGameConfigs.GetRpgMakerGameChapterName(chapterId)
    self.BtnPlotTab:SetRawImage(bg)
    self.BtnPlotTab:SetNameByGroup(0, name)
end

function XUiRpgMakerGameTabBtn:Refresh()
    local chapterId = self:GetChapterId()
    local totalStarCount = XRpgMakerGameConfigs.GetRpgMakerGameTotalStar(chapterId)
    local currStarCount = XDataCenter.RpgMakerGameManager.GetRpgMakerChapterClearStarCount(chapterId)
    local isClear = currStarCount >= totalStarCount

    -- 首次解锁章节展示小红点
    self.BtnPlotTab:ShowReddot(XDataCenter.RpgMakerGameManager.CheckChapterBtnRedPoint(chapterId))

    self.BtnPlotTab:SetNameByGroup(1, currStarCount)
    self.BtnPlotTab:SetNameByGroup(2, "/" .. totalStarCount)
    self.TagStar.gameObject:SetActiveEx(not isClear)
    self.TagClear.gameObject:SetActiveEx(isClear)
    
end

function XUiRpgMakerGameTabBtn:RefreshTimer()
    local chapterId = self:GetChapterId()
    local isUnLock = XDataCenter.RpgMakerGameManager.IsChapterUnLock(chapterId)
    if not isUnLock and self.BtnPlotTab.ButtonState ~= ButtonStateDisable then
        self.BtnPlotTab:SetDisable(true)
    elseif isUnLock and self.BtnPlotTab.ButtonState == ButtonStateDisable then
        self.BtnPlotTab:SetDisable(false)
    end

    if not isUnLock then
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameChapterOpenTimeId(chapterId)
        local time = XFunctionManager.GetStartTimeByTimeId(timeId)
        local serverTimestamp = XTime.GetServerNowTimestamp()
        if self.TextTagTime then
            self.TextTagTime.text = CS.XTextManager.GetText("ScheOpenCountdown", XUiHelper.GetTime(time - serverTimestamp, XUiHelper.TimeFormatType.RPG_MAKER_GAME))
        end
    end

    if self.TagTime then
        self.TagTime.gameObject:SetActiveEx(not isUnLock)
    end
end

function XUiRpgMakerGameTabBtn:GetChapterId()
    return self.ChapterId
end

function XUiRpgMakerGameTabBtn:GetTabBtnIndex()
    return self.TabBtnIndex
end

return XUiRpgMakerGameTabBtn