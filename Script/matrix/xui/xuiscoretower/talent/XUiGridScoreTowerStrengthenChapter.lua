---@class XUiGridScoreTowerStrengthenChapter : XUiNode
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerStrengthenChapter = XClass(XUiNode, "XUiGridScoreTowerStrengthenChapter")

function XUiGridScoreTowerStrengthenChapter:OnStart(onClick)
    self.OnSelectCallback = onClick
    self.GridTalent.gameObject:SetActiveEx(false)
    ---@type XUiGridScoreTowerStrengthen[]
    self.GridStrengthenList = {}
end

function XUiGridScoreTowerStrengthenChapter:OnDisable()
    self:StopEnableAnimDelayTimer()
    self:SetCanvasGroupAlpha(1)
end

---@param chapterId number 章节ID
---@param enableAnimDelay number 动画延迟时间
function XUiGridScoreTowerStrengthenChapter:Refresh(chapterId, enableAnimDelay)
    self.ChapterId = chapterId
    -- 章节名称
    self.TxtTitle.text = self._Control:GetChapterName(chapterId)
    self:RefreshStrengthenBuff()
    -- 是否通关
    local isPass = self._Control:IsChapterPass(chapterId)
    self.PanelLock.gameObject:SetActiveEx(not isPass)
    if not isPass then
        local desc = self._Control:GetClientConfig("StrengthenChapterUnlockDesc")
        self.TxtLock.text = XUiHelper.FormatText(desc, self._Control:GetChapterName(chapterId))
    end
    -- 刷新红点
    self:RefreshRedPoint()
    self:TryPlayEnableAnim(enableAnimDelay)
end

-- 刷新强化Buff
function XUiGridScoreTowerStrengthenChapter:RefreshStrengthenBuff()
    local strengthenIdList = self._Control:GetStrengthenIdsByChapterId(self.ChapterId)
    for index = 1, XEnumConst.ScoreTower.MaxStrengthenSlotCount do
        local grid = self.GridStrengthenList[index]
        local strengthenId = strengthenIdList[index] or 0
        if XTool.IsNumberValid(strengthenId) then
            if not grid then
                local go = XUiHelper.Instantiate(self.GridTalent, self.ListTalent)
                grid = require("XUi/XUiScoreTower/Talent/XUiGridScoreTowerStrengthen").New(go, self, handler(self, self.OnSelectClick))
                self.GridStrengthenList[index] = grid
            end
            grid:Open()
            grid:Refresh(strengthenId)
        elseif grid then
            grid:Close()
        end
    end
end

-- 刷新红点
function XUiGridScoreTowerStrengthenChapter:RefreshRedPoint()
    local isPass = self._Control:IsChapterPass(self.ChapterId)
    for _, grid in pairs(self.GridStrengthenList) do
        if grid:IsNodeShow() then
            grid:RefreshRedPoint(isPass)
        end
    end
end

---@param grid XUiGridScoreTowerStrengthen
function XUiGridScoreTowerStrengthenChapter:OnSelectClick(strengthenId, grid)
    if self.OnSelectCallback then
        self.OnSelectCallback(self.ChapterId, strengthenId, grid)
    end
end

-- 模拟点击
function XUiGridScoreTowerStrengthenChapter:SimulateClick()
    -- 默认选中第一个
    local grid = self.GridStrengthenList[1]
    if grid and self.OnSelectCallback then
        self.OnSelectCallback(self.ChapterId, grid:GetStrengthenId(), grid, true)
    end
end

--region 动画

---@param delayTime number 动画延迟时间
function XUiGridScoreTowerStrengthenChapter:TryPlayEnableAnim(delayTime)
    self:StopEnableAnimDelayTimer()
    self:SetCanvasGroupAlpha(0)
    self._EnableAnimDelayTimer = XScheduleManager.ScheduleOnce(function()
        self:PlayGridChapterEnable()
    end, delayTime)
end

-- 播放动画
function XUiGridScoreTowerStrengthenChapter:PlayGridChapterEnable()
    self:PlayAnimation("GridChapterEnable", function()
        self:SetCanvasGroupAlpha(1)
    end)
end

-- 停止动画延迟计时器
function XUiGridScoreTowerStrengthenChapter:StopEnableAnimDelayTimer()
    if self._EnableAnimDelayTimer then
        XScheduleManager.UnSchedule(self._EnableAnimDelayTimer)
        self._EnableAnimDelayTimer = nil
    end
end

-- 设置透明度
function XUiGridScoreTowerStrengthenChapter:SetCanvasGroupAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

--endregion

return XUiGridScoreTowerStrengthenChapter
