---@class XUiGridScoreTowerChapter : XUiNode
---@field private _Control XScoreTowerControl
---@field Parent XUiScoreTowerMain
local XUiGridScoreTowerChapter = XClass(XUiNode, "XUiGridScoreTowerChapter")

function XUiGridScoreTowerChapter:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClick, nil, true)
    self.GridStar.gameObject:SetActiveEx(false)
    self.PanelProgress.gameObject:SetActiveEx(false)
    self.PanelScore.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStarList = {}
end

function XUiGridScoreTowerChapter:OnDisable()
    self:StopEnableAnimDelayTimer()
    self:SetCanvasGroupAlpha(1)
    self:SetBgActive(true)
end

---@param chapterId number 章节ID
function XUiGridScoreTowerChapter:Refresh(chapterId)
    self.ChapterId = chapterId
    self:RefreshInfo()
end

function XUiGridScoreTowerChapter:RefreshInfo()
    -- 章节名称
    self.TxtName.text = self._Control:GetChapterName(self.ChapterId)
    -- 章节星级
    local curStar = self._Control:GetChapterCurStar(self.ChapterId)
    local totalStar = self._Control:GetChapterTotalStar(self.ChapterId)
    self:RefreshStar(curStar, totalStar)
    -- 章节是否满星通关
    local isPass = totalStar > 0 and curStar >= totalStar
    self.CommonClear.gameObject:SetActiveEx(isPass)
    -- 章节是否解锁
    local isUnlock, desc = self._Control:IsChapterUnlock(self.ChapterId)
    self.TxtName.gameObject:SetActiveEx(isUnlock)
    self.PanelStar.gameObject:SetActiveEx(isUnlock)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    self.TxtLock.text = desc
    -- 章节是否正在进行中
    local isProgress = self._Control:IsChapterProgress(self.ChapterId)
    self.PanelProgress.gameObject:SetActiveEx(isProgress)
    -- 章节分数
    self.PanelScore.gameObject:SetActiveEx(isUnlock and not isProgress)
    local score = self._Control:GetChapterCurPoint(self.ChapterId)
    self.TxtScore1.text = score
    self.TxtScore2.text = score
    -- 刷新红点
    local isShowRed = self._Control:CheckChapterRedPoint(self.ChapterId)
    self.BtnChapter:ShowReddot(isShowRed)
end

-- 刷新章节星级
---@param curStar number 当前星级
---@param totalStar number 总星级
function XUiGridScoreTowerChapter:RefreshStar(curStar, totalStar)
    for i = 1, totalStar do
        local grid = self.GridStarList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridStar, self.PanelStar)
            self.GridStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("ImgStarOff").gameObject:SetActiveEx(i > curStar)
        grid:GetObject("ImgStarOn").gameObject:SetActiveEx(i <= curStar)
    end
    for i = totalStar + 1, #self.GridStarList do
        self.GridStarList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridScoreTowerChapter:OnBtnChapterClick()
    -- 章节是否解锁
    local isUnlock, desc = self._Control:IsChapterUnlock(self.ChapterId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
        return
    end
    -- 正在进行中的章节Id
    local curChapterId = self._Control:GetCurrentChapterId()
    if curChapterId <= 0 then
        XLuaUiManager.Open("UiScoreTowerChapterDetail", self.ChapterId)
        return
    end
    -- 正在进行中的塔Id
    local curTowerId = self._Control:GetCurrentTowerId(curChapterId)
    if curTowerId <= 0 then
        return
    end
    if curChapterId == self.ChapterId then
        XLuaUiManager.Open("UiScoreTowerStoreyDetail", self.ChapterId, curTowerId)
    else
        self.Parent:AdvanceSettleRequest(curTowerId)
    end
end

--region 动画

---@param delayTime number 动画延迟时间
function XUiGridScoreTowerChapter:TryPlayEnableAnim(delayTime)
    self:StopEnableAnimDelayTimer()
    self:SetCanvasGroupAlpha(0)
    self:SetBgActive(false)
    self._EnableAnimDelayTimer = XScheduleManager.ScheduleOnce(function()
        self:PlayEnableAnim()
    end, delayTime)
end

-- 播放动画
function XUiGridScoreTowerChapter:PlayEnableAnim()
    self:PlayAnimation("Enable", function()
        self:SetCanvasGroupAlpha(1)
    end, function()
        self:SetBgActive(true)
    end)
end

-- 停止动画延迟计时器
function XUiGridScoreTowerChapter:StopEnableAnimDelayTimer()
    if self._EnableAnimDelayTimer then
        XScheduleManager.UnSchedule(self._EnableAnimDelayTimer)
        self._EnableAnimDelayTimer = nil
    end
end

-- 设置透明度
function XUiGridScoreTowerChapter:SetCanvasGroupAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

-- 设置背景是否激活
function XUiGridScoreTowerChapter:SetBgActive(isActive)
    if self.RImgBg then
        self.RImgBg.gameObject:SetActiveEx(isActive)
    end
end

--endregion

return XUiGridScoreTowerChapter
