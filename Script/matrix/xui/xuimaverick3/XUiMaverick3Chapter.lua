---@class XUiMaverick3Chapter : XLuaUi 孤胆枪手关卡选择
---@field _Control XMaverick3Control
local XUiMaverick3Chapter = XLuaUiManager.Register(XLuaUi, "UiMaverick3Chapter")

local Normal = XEnumConst.Maverick3.Difficulty.Normal
local Hard = XEnumConst.Maverick3.Difficulty.Hard

local DelayTimes = { 0, 160, 320 }
local SwitchDelayTimes = { 330, 490, 650 }

function XUiMaverick3Chapter:OnAwake()
    ---@type XUiGridMaverick3Stage[]
    self._GridStages = {}
    self._Timers = {}

    self.BtnSwitch.CallBack = handler(self, self.OnBtnSwitchClick)
    self:BindHelpBtn(self.BtnHelp, "Maverick3ChapterHelp")
end

function XUiMaverick3Chapter:OnStart()
    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)

    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.GridStage1.gameObject:SetActiveEx(false)
    self.GridStage2.gameObject:SetActiveEx(false)
    self.PanelChapter.gameObject:SetActiveEx(false)
    self.PanelChapter2.gameObject:SetActiveEx(false)

    ---@type table<number, XTableMaverick3Chapter[]>
    self._ChapterMap = {}
    self._ChapterMap[Normal] = {}
    self._ChapterMap[Hard] = {}
    local chapters = self._Control:GetChapterConfigs()
    for _, chapter in pairs(chapters) do
        if chapter.Type == XEnumConst.Maverick3.ChapterType.MainLine then
            table.insert(self._ChapterMap[chapter.Difficult], chapter)
        end
    end
    for _, tb in pairs(self._ChapterMap) do
        table.sort(tb, function(a, b)
            return a.ChapterId < b.ChapterId
        end)
    end
end

function XUiMaverick3Chapter:OnEnable()
    -- 自动选中当前章节
    local newChapterId = self._Control:GetCurSelectChapterId()
    local newChapterCfg = self._Control:GetChapterById(newChapterId)
    self:SetDifficulty(newChapterCfg.Difficult)
    self.RImgBg1.gameObject:SetActiveEx(self._CurDifficulty == Normal)
    self.RImgBg2.gameObject:SetActiveEx(self._CurDifficulty == Hard)
    
    -- 如果困难关全都没解锁 则不可切换为困难模式
    local hardChapter = self._ChapterMap[Hard][1]
    self._IsSwitchUnlock, self._SwitchLockDesc = self._Control:IsChapterUnlock(hardChapter.ChapterId)
    if self._IsSwitchUnlock then
        if self._CurDifficulty == Normal then
            self.BtnSwitch:SetButtonState(XUiButtonState.Select)
        else
            self.BtnSwitch:SetButtonState(XUiButtonState.Normal)
        end
    else
        self.BtnSwitch:SetButtonState(XUiButtonState.Disable)
    end

    self:UpdateBtnGroup()

    if self.PanelStage.gameObject.activeSelf then
        for i, v in ipairs(self._ChapterMap[self._CurDifficulty]) do
            if v.ChapterId == newChapterId then
                self._CurBtnGroup:SelectIndex(i)
                break
            end
        end
    end

    self:UpdateSwitchRedPoint()

    local id = self._Control:GetNeedOpenChapterDetailId()
    if XTool.IsNumberValid(id) then
        local chapterId = self._Control:GetStageById(id).ChapterId
        if self._Control:GetChapterById(chapterId).Difficult == XEnumConst.Maverick3.Difficulty.Normal then
            XLuaUiManager.Open("UiMaverick3PopupChapterDetail", id)
        else
            XLuaUiManager.Open("UiMaverick3PopupChapterDetailRed", id)
        end
    end
end

function XUiMaverick3Chapter:OnDisable()
    self:HideAllStage()
end

function XUiMaverick3Chapter:OnDestroy()
    self:RemoveTimer()
end

function XUiMaverick3Chapter:UpdateBtnGroup()
    ---@type XUiComponent.XUiButton[]
    self._Btns = {}
    local btns = {}
    local datas = self._ChapterMap[self._CurDifficulty]
    local btnTab = self._CurDifficulty == Normal and self.BtnTab1 or self.BtnTab2
    XUiHelper.RefreshCustomizedList(btnTab.parent, btnTab, #datas, function(i, btn)
        local cfg = datas[i]
        local cur, all = self._Control:GetChapterProgress(cfg.ChapterId)
        local isUnlock = self._Control:IsChapterUnlock(cfg.ChapterId)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, btn)
        uiObject.BtnTab:SetNameByGroup(0, cfg.Name)
        uiObject.BtnTab:SetNameByGroup(1, string.format("%s%%", math.floor(cur / all * 100)))
        uiObject.BtnTab:SetButtonState(isUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
        table.insert(btns, uiObject.BtnTab)
        self._Btns[cfg.ChapterId] = uiObject.BtnTab
    end)
    self._CurBtnGroup:Init(btns, function(i)
        self:UpdateStages(i)
    end)
end

function XUiMaverick3Chapter:UpdateStages(index)
    local datas = self._ChapterMap[self._CurDifficulty]
    local chapterId = datas[index].ChapterId

    local isUnlock, desc = self._Control:IsChapterUnlock(chapterId)
    if not isUnlock then
        XUiManager.TipError(desc)
        return
    end

    self:RemoveTimer()

    local isSelectTab = XTool.IsNumberValid(self._CurSelectChapterIdx) and not self._IsPlayingSwitchAnim
    if isSelectTab then
        self:PlayAnimationWithMask("QieHuan")
    end

    self._CurSelectChapterIdx = index
    self._Control:SetCurSelectChapterId(chapterId)
    
    self._LastBg = datas[index].Bg
    self.RImgBg1:SetRawImage(self._LastBg)
    self.RImgBg2:SetRawImage(self._LastBg)

    for i = 1, #datas do
        local listName = "ListStage" .. i
        if XTool.UObjIsNil(self[listName]) then
            XLog.Error("缺少UI节点：" .. listName)
        else
            self[listName].gameObject:SetActiveEx(index == i)
        end
    end

    self:HideAllStage()

    local stages = self._Control:GetStagesByChapterId(chapterId)
    for i, v in ipairs(stages) do
        local stageName = "GridStage" .. index .. i
        if XTool.UObjIsNil(self[stageName]) then
            XLog.Error("缺少UI节点：" .. stageName)
        else
            local grid = self._GridStages[v.StageId]
            if not grid then
                local go = XUiHelper.Instantiate(self._CurDifficulty == Normal and self.GridStage1 or self.GridStage2, self[stageName])
                go.gameObject:SetActiveEx(true)
                grid = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Stage").New(go, self)
                self._GridStages[v.StageId] = grid
            end
            if isSelectTab then
                grid:Open()
                grid:SetData(v.StageId)
                XUiHelper.PlayUiNodeAnimation(grid.Transform, "GridStageEnable")
            else
                grid:Close()
                local timer = XScheduleManager.ScheduleOnce(function()
                    grid:Open()
                    grid:SetData(v.StageId)
                    XUiHelper.PlayUiNodeAnimation(grid.Transform, "GridStageEnable")
                end, self._IsPlayingSwitchAnim and SwitchDelayTimes[i] or DelayTimes[i])
                table.insert(self._Timers, timer)
            end
        end
    end

    self._Control:CloseChapterRed(chapterId)
    self:UpdateBtnRedPoint()
end

function XUiMaverick3Chapter:HideAllStage()
    for _, grid in pairs(self._GridStages) do
        grid:Close()
    end
end

function XUiMaverick3Chapter:RemoveTimer()
    for _, timer in pairs(self._Timers) do
        XScheduleManager.UnSchedule(timer)
    end
end

function XUiMaverick3Chapter:UpdateBtnRedPoint()
    for chapterId, btn in pairs(self._Btns) do
        btn:ShowReddot(self._Control:IsChapterRed(chapterId))
    end
end

function XUiMaverick3Chapter:UpdateSwitchRedPoint()
    if self._IsSwitchUnlock then
        if self._CurDifficulty == Normal then
            self.BtnSwitch:ShowReddot(self._Control:IsMainLineNormalRed())
        else
            self.BtnSwitch:ShowReddot(self._Control:IsMainLineHardRed())
        end
    else
        self.BtnSwitch:ShowReddot(false)
    end
end

function XUiMaverick3Chapter:OnBtnSwitchClick()
    if not self._IsSwitchUnlock then
        XUiManager.TipError(self._SwitchLockDesc)
        return
    end
    if self._CurDifficulty == Normal then
        self:SetDifficulty(Hard)
        self:PlayAnimationWithMask("QieHuanMode", nil, function()
            self.RImgBg1.gameObject:SetActiveEx(false)
            self.RImgBg2.gameObject:SetActiveEx(true)
            self.RImgBg:SetRawImage(self._LastBg)
        end)
    else
        self:SetDifficulty(Normal)
        self:PlayAnimationWithMask("QieHuanMode", nil, function()
            self.RImgBg2.gameObject:SetActiveEx(false)
            self.RImgBg1.gameObject:SetActiveEx(true)
            self.RImgBg:SetRawImage(self._LastBg)
        end)
    end
    self:UpdateBtnGroup()
    self._IsPlayingSwitchAnim = true -- 切换动画已经被做进QieHuanMode了
    self._CurBtnGroup:SelectIndex(1)
    self._IsPlayingSwitchAnim = false
    self:UpdateSwitchRedPoint()
end

function XUiMaverick3Chapter:SetDifficulty(difficulty)
    self._CurDifficulty = difficulty
    ---@type XUiButtonGroup
    self._CurBtnGroup = self._CurDifficulty == Normal and self.TabBtnGroup1 or self.TabBtnGroup2
    self.TabBtnGroup1.gameObject:SetActiveEx(self._CurDifficulty == Normal)
    self.TabBtnGroup2.gameObject:SetActiveEx(self._CurDifficulty == Hard)
    self.PanelLine1.gameObject:SetActiveEx(self._CurDifficulty == Normal)
    self.PanelLine2.gameObject:SetActiveEx(self._CurDifficulty == Hard)
    self.ImgTop.color = XUiHelper.Hexcolor2Color(self._CurDifficulty == Normal and "4CCEE317" or "E74F2A17")
    self.ImgBottom.color = XUiHelper.Hexcolor2Color(self._CurDifficulty == Normal and "4CCEE317" or "E74F2A17")
end

---@param stageCfg XTableMaverick3Stage
function XUiMaverick3Chapter:OnDetailOpen(stageCfg)
    self.PanelStage.gameObject:SetActiveEx(false)
    self.PanelLeft.gameObject:SetActiveEx(false)
    if self._CurDifficulty == Normal then
        self.PanelChapter.gameObject:SetActiveEx(true)
        self.PanelChapter2.gameObject:SetActiveEx(false)
        self.ImgChapter:SetRawImage(stageCfg.Icon)
        self.ImgChapterBg:SetRawImage(stageCfg.Icon)
        self.Chapter1ImgChapter1:SetRawImage(stageCfg.Icon)
    else
        self.PanelChapter.gameObject:SetActiveEx(false)
        self.PanelChapter2.gameObject:SetActiveEx(true)
        self.ImgChapter2:SetRawImage(stageCfg.Icon)
        self.ImgChapterBg2:SetRawImage(stageCfg.Icon)
        self.Chapter2ImgChapter2:SetRawImage(stageCfg.Icon)
    end
end

function XUiMaverick3Chapter:OnDetailClose()
    self.PanelStage.gameObject:SetActiveEx(true)
    self.PanelLeft.gameObject:SetActiveEx(true)
    self.PanelChapter.gameObject:SetActiveEx(false)
    self.PanelChapter2.gameObject:SetActiveEx(false)
    self._CurBtnGroup:SelectIndex(self._CurSelectChapterIdx)
end

return XUiMaverick3Chapter