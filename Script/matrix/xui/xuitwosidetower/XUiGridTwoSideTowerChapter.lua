---@class XUiGridTwoSideTowerChapter : XUiNode
---@field _Control XTwoSideTowerControl
---@field BtnChapter XUiComponent.XUiButton
local XUiGridTwoSideTowerChapter = XClass(XUiNode, "XUiGridTwoSideTowerChapter")

function XUiGridTwoSideTowerChapter:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClick)

    self.ScoreIconList = {
        [1] = {
            self.RImgRankNormalA,
            self.RImgRankPressA,
        },
        [2] = {
            self.RImgRankNormalS,
            self.RImgRankPressS,
        },
        [3] = {
            self.RImgRankNormalSS,
            self.RImgRankPressSS,
        },
        [4] = {
            self.RImgRankNormalSSS,
            self.RImgRankPressSSS,
        },
    }
end

function XUiGridTwoSideTowerChapter:Refresh(chapterId)
    self.ChapterId = chapterId
    -- 图片
    self.BtnChapter:SetRawImage(self._Control:GetChapterIcon(chapterId))
    -- 名称
    self.BtnChapter:SetNameByGroup(0, self._Control:GetChapterName(chapterId))
    -- 是否解锁
    local unlock, desc = self._Control:CheckChapterIsUnlock(chapterId)
    self.BtnChapter:SetNameByGroup(1, desc)
    self.BtnChapter:SetDisable(not unlock)
    -- 积分等级
    local isClear = self._Control:CheckChapterCleared(chapterId)
    local maxScoreLv = self._Control:GetMaxChapterScoreLevel(chapterId)
    for i, scoreIcon in pairs(self.ScoreIconList) do
        local isShow = i == maxScoreLv and isClear
        for _, v in pairs(scoreIcon) do
            if not XTool.UObjIsNil(v) then
                v.gameObject:SetActiveEx(isShow)
            end
        end
    end
    -- 刷新红点
    local isShowRedPoint = self._Control:CheckNewChapterOpenRedPoint({ chapterId })
    self.BtnChapter:ShowReddot(isShowRedPoint)
end

function XUiGridTwoSideTowerChapter:OnBtnChapterClick()
    -- 是否解锁
    local unlock, desc = self._Control:CheckChapterIsUnlock(self.ChapterId)
    if not unlock then
        XUiManager.TipMsg(desc)
        return
    end
    -- 保存点击
    self._Control:SaveChapterIsClick(self.ChapterId)
    XLuaUiManager.Open("UiTwoSideTowerMainLine", self.ChapterId)
end

return XUiGridTwoSideTowerChapter
