---@class XUiGridGame2048Chapter: XUiNode
---@field _Control XGame2048Control
local XUiGridGame2048Chapter = XClass(XUiNode, 'XUiGridGame2048Chapter')

function XUiGridGame2048Chapter:OnStart(chapterId, chapterIndex)
    self._ChapterId = chapterId
    self._ChapterIndex = chapterIndex
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
end

function XUiGridGame2048Chapter:SetEnterAnimationName(animationName)
    self._EnterAnimationName = animationName
end

function XUiGridGame2048Chapter:Refresh()
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)
    
    self._Unlock = XMVCA.XGame2048:CheckChapterUnLockById(self._ChapterId)
    self.PanelStar.gameObject:SetActiveEx(self._Unlock)
    self.PanelLock.gameObject:SetActiveEx(not self._Unlock)
    self.Clear.gameObject:SetActiveEx(false)

    if self._Unlock then
        local curStarSummary = self._Control:GetChapterCurStarSummary(self._ChapterId)
        local totalStarSummary = self._Control:GetChapterStarTotalById(self._ChapterId)
        -- 星数
        self.TxtStarNum.text = XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterProgressShowLabel'), curStarSummary, totalStarSummary)

        self.Clear.gameObject:SetActiveEx(curStarSummary >= totalStarSummary)
    
        self.GridBtn:ShowReddot(XMVCA.XGame2048:CheckChapterIsNew(self._ChapterId))
        
        -- 刷新是否显示放弃按钮
        self._IsNotPlayingChapter = false
        self._IsAnyStagePlaying = false
        local stageData = self._Control:GetCurStageData()

        if stageData then
            local stageId = stageData.StageId
            local chapterId = XTool.IsNumberValid(stageId) and self._Control:GetChapterIdByStageId(stageId) or 0

            self._IsNotPlayingChapter = chapterId ~= self._ChapterId

            self._IsAnyStagePlaying = not self._IsNotPlayingChapter
        end

        if self.PanelOngoing then
            self.PanelOngoing.gameObject:SetActiveEx(self._IsAnyStagePlaying)
        end
    else
        self._UnLockLeftTime = self._Control:GetChapterUnLockLeftTime(self._ChapterId)
        self._UnLockConditionDesc = self._Control:GetChapterUnLockConditionDesc(self._ChapterId)
        
        local lockDesc = ''

        if XTool.IsNumberValid(self._UnLockLeftTime) then
            local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
            lockDesc = XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterLeftTimeTips'), leftTimeStr)
        else
            lockDesc = not string.IsNilOrEmpty(self._UnLockConditionDesc) and self._UnLockConditionDesc or self._Control:GetClientConfigText('NotInTimeCommonTips')
        end
        
        self.TxtLock.text = lockDesc
    end
end

function XUiGridGame2048Chapter:OnClickEvent()
    if self._Unlock then
        local stageData = self._Control:GetCurStageData()

        if stageData then
            local stageId = stageData.StageId
            local chapterId = XTool.IsNumberValid(stageId) and self._Control:GetChapterIdByStageId(stageId) or 0

            if chapterId ~= self._ChapterId then
                XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), self._Control:GetClientConfigText('GiveupTipsForChapterEnter'), nil, nil, function()
                    self._Control:RequestGame2048GiveUp(function()
                        --todo 暂时移除旧动画
                        --[[self.Parent:PlayAnimationWithMask(self._EnterAnimationName, function()
                            XLuaUiManager.Open('UiGame2048Chapter', self._ChapterId, self._ChapterIndex)
                            XMVCA.XGame2048:SetChapterToOld(self._ChapterId)
                        end)--]]

                        XLuaUiManager.Open('UiGame2048Chapter', self._ChapterId, self._ChapterIndex)
                        XMVCA.XGame2048:SetChapterToOld(self._ChapterId)
                    end)
                end)
                return
            end
        end

        --[[ todo 暂时移除旧动画
        self.Parent:PlayAnimationWithMask(self._EnterAnimationName, function()
            XLuaUiManager.Open('UiGame2048Chapter', self._ChapterId, self._ChapterIndex)
            XMVCA.XGame2048:SetChapterToOld(self._ChapterId)
        end)--]]

        XLuaUiManager.Open('UiGame2048Chapter', self._ChapterId, self._ChapterIndex)
        XMVCA.XGame2048:SetChapterToOld(self._ChapterId)
    else
        if XTool.IsNumberValid(self._UnLockLeftTime) then
            local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
            XUiManager.TipMsg(XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterLeftTimeTips'), leftTimeStr))
        else
            if not string.IsNilOrEmpty(self._UnLockConditionDesc) then
                XUiManager.TipMsg(self._UnLockConditionDesc)
            else
                XUiManager.TipMsg(self._Control:GetClientConfigText('NotInTimeCommonTips'))
            end
        end
    end    
end

return XUiGridGame2048Chapter