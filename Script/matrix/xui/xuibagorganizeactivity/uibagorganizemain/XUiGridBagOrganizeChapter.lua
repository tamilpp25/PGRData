---@class XUiGridBagOrganizeChapter: XUiNode
---@field _Control XBagOrganizeActivityControl
local XUiGridBagOrganizeChapter = XClass(XUiNode, 'XUiGridBagOrganizeChapter')

function XUiGridBagOrganizeChapter:OnStart(chapterId, chapterIndex)
    self._ChapterId = chapterId
    self._ChapterIndex = chapterIndex
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
end

function XUiGridBagOrganizeChapter:Refresh()
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)
    self._Unlock = XMVCA.XBagOrganizeActivity:CheckChapterUnLockById(self._ChapterId)
    
    self.PanelLock.gameObject:SetActiveEx(not self._Unlock)
    self.PanelProgress.gameObject:SetActiveEx(self._Unlock)
    self.RImgBg.gameObject:SetActiveEx(self._Unlock)

    if self._Unlock then
        -- 分数
        self.TxtNum.text = XMath.ToMinInt(self._Control:GetChapterProgressById(self._ChapterId)*100)..'%'
    
        self.GridBtn:ShowReddot(XMVCA.XBagOrganizeActivity:CheckChapterIsNew(self._ChapterId))
    else
        self._UnLockLeftTime = self._Control:GetChapterUnLockLeftTime(self._ChapterId)
        self.GridBtn:ShowReddot(false)
        
        local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
        self.TxtLock.text = XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterLeftTimeTips'), leftTimeStr)
    end
end

function XUiGridBagOrganizeChapter:OnClickEvent()
    if self._Unlock then
        ---2.0 新增：如果章节只有一关，那么直接进入该关卡
        local stageIds = self._Control:GetChapterStageIdsById(self._ChapterId)

        if XTool.GetTableCount(stageIds) == 1 then
            self._Control:SetCurStageId(stageIds[1])
            XMVCA.XBagOrganizeActivity:RequestBagOrganizeStart(stageIds[1], function()
                self._Control:StartGameInit()
                XMVCA.XBagOrganizeActivity:SetChapterToOld(self._ChapterId)
                XLuaUiManager.Open('UiBagOrganizeGame', stageIds[1])
            end)
        else
            XLuaUiManager.Open('UiBagOrganizeChapter', self._ChapterId, self._ChapterIndex)
            XMVCA.XBagOrganizeActivity:SetChapterToOld(self._ChapterId)
        end
    else
        if XTool.IsNumberValid(self._UnLockLeftTime) then
            local leftTimeStr = XUiHelper.GetTime(self._UnLockLeftTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
            XUiManager.TipMsg(XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterLeftTimeTips'), leftTimeStr))
        else
            XUiManager.TipMsg(self._Control:GetClientConfigText('NotInTimeCommonTips'))
        end
    end    
end

return XUiGridBagOrganizeChapter