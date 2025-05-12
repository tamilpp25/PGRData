---@class XUiGridMechanismChapter
---@field _Control XMechanismActivityControl
local XUiGridMechanismChapter = XClass(XUiNode, 'XUiGridMechanismChapter')

function XUiGridMechanismChapter:OnStart()
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
end

function XUiGridMechanismChapter:Refresh(chapterId)
    if XTool.IsNumberValid(chapterId) then
        self._ChapterId = chapterId
    end

    if not XTool.IsNumberValid(self._ChapterId) then
        self:Close()
        return
    end
    
    self._UnLock = XMVCA.XMechanismActivity:CheckChapterUnLock(self._ChapterId)
    
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)
    self.ImgBg:SetRawImage(self._Control:GetChapterIconById(self._ChapterId))
    
    self:SetIsLock(not self._UnLock)
    if self._UnLock then
        self:SetStarProcess()
    else
        self._UnLockLeftTime = self._Control:GetChapterUnLockLeftTime(self._ChapterId)

        local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
        self.TxtLock.text = XUiHelper.FormatText(self._Control:GetMechanismClientConfigStr('ChapterLeftTimeTips'), leftTimeStr)
    end
    
    -- 蓝点
    self.GridBtn:ShowReddot(self._UnLock and ( not self._Control:CheckChapterIsOld(self._ChapterId) or XMVCA.XMechanismActivity:CheckHasNewStageByChapterId(self._ChapterId) ))
end

function XUiGridMechanismChapter:SetIsLock(isLock)
    self.PanelStar.gameObject:SetActiveEx(not isLock)
    self.PanelLock.gameObject:SetActiveEx(isLock)
end

function XUiGridMechanismChapter:SetStarProcess()
    local totalCount = self._Control:GetStarLimitByChapterId(self._ChapterId)
    local curCount = self._Control:GetSumStarOfStagesById(self._ChapterId)
    
    self.StarTxt.text = tostring(curCount)..'/'..tostring(totalCount)
    self.ImgBar.fillAmount = curCount/totalCount
end

function XUiGridMechanismChapter:OnClickEvent()
    if self._UnLock then
        XLuaUiManager.Open('UiMechanismChapter', self._ChapterId)
        if not self._Control:CheckChapterIsOld(self._ChapterId) then
            self._Control:SetChapterToOld(self._ChapterId)
        end
    else
        if XTool.IsNumberValid(self._UnLockLeftTime) then
            local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
            XUiManager.TipMsg(XUiHelper.FormatText(self._Control:GetMechanismClientConfigStr('ChapterLeftTimeTips'), leftTimeStr))
        else
            XUiManager.TipMsg(self._Control:GetMechanismClientConfigStr('NotInTimeCommonTips'))
        end
    end
end


return XUiGridMechanismChapter