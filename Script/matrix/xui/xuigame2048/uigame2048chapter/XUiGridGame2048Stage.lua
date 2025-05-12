---@class XUiGridGame2048Stage: XUiNode
---@field _Control XGame2048Control
local XUiGridGame2048Stage = XClass(XUiNode, 'XUiGridGame2048Stage')
local XUiGridGame2048StageStar = require('XUi/XUiGame2048/UiGame2048Chapter/XUiGridGame2048StageStar')

function XUiGridGame2048Stage:OnStart(stageId, stageIndex)
    self._StageId = stageId
    self._StageIndex = stageIndex
    
    self.GridStar.gameObject:SetActiveEx(false)
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)

    if self.BtnGiveUp then
        self.BtnGiveUp.CallBack = handler(self, self.OnBtnGiveUpClick)
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

function XUiGridGame2048Stage:GetStageId()
    return self._StageId
end

function XUiGridGame2048Stage:Refresh()
    self.GridBtn:SetNameByGroup(0, self._Control:GetStageNameById(self._StageId))
    
    self._UnLock, self._PreStageId = XMVCA.XGame2048:CheckUnlockByStageId(self._StageId)

    if not XTool.IsNumberValid(self._PreStageId) then
        -- 时间限制
        local timeId = self._Control:GetStageTimeId(self._StageId)

        if XTool.IsNumberValid(timeId) then
            local now = XTime.GetServerNowTimestamp()
            self._StartLeftTime = XFunctionManager.GetStartTimeByTimeId(timeId) - now

            if self._StartLeftTime < 0 then
                self._StartLeftTime = 0
            end
            
            self._StopLeftTime = XFunctionManager.GetEndTimeByTimeId(timeId) - now
        elseif not self._UnLock then
            XLog.Error('关卡锁定，但没有前置关卡约束，也无时间约束')
        end
    end
    
    self._StageType = self._Control:GetStageTypeById(self._StageId)
    self.GridBtn:SetButtonState(self._UnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.TxtScore.gameObject:SetActiveEx(self._UnLock and self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless)
    self.GridStar.transform.parent.gameObject:SetActiveEx(self._UnLock and self._StageType == XMVCA.XGame2048.EnumConst.StageType.Normal)

    
    -- 更新关卡贴图
    local curChapterId = self._Control:GetCurChapterId()
    local fullBg = self._Control:GetChapterStageEntranceIconById(curChapterId)
    local fullBgInSelect = self._Control:GetChapterStageEntranceSelectedIconById(curChapterId)
    self.GridBtn:SetRawImage(fullBg)
    --self.SelectedImg:SetRawImage(fullBgInSelect)
    --self.RImgFace.gameObject:SetActiveEx(self._UnLock)
    
    if self._UnLock then
        self.CommonFuBenClear.gameObject:SetActiveEx(self._Control:GetStageCurStarCountById(self._StageId) >= #self._Control:GetStageStarRewardIds(self._StageId))
        --self.RImgFace:SetRawImage(self._Control:GetStageEntranceEmojiIcon(self._StageId))

        if self._StageType == XMVCA.XGame2048.EnumConst.StageType.Normal then
            -- 普通关显示星级
            if self._StarGrids == nil then
                self._StarGrids = {}
            end
            local curTargetCount = self._Control:GetStageCurStarCountById(self._StageId)
            local targetCount = #self._Control:GetStageStarRewardIds(self._StageId)
            XUiHelper.RefreshCustomizedList(self.GridStar.transform.parent, self.GridStar, targetCount, function(index, go)
                local grid = self._StarGrids[index]

                if not grid then
                    grid = XUiGridGame2048StageStar.New(go, self)
                    grid:Open()
                end

                grid:SetIsOn(curTargetCount >= index)
            end)
        elseif self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless then
            --无尽关显示分数    
            local maxScore = self._Control:GetStageMaxScoreById(self._StageId)
            if XTool.IsNumberValid(maxScore) then
                self.TxtScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('BaseScoreLabel'), maxScore)
            else
                self.TxtScore.gameObject:SetActiveEx(false)
            end
        end
    else
        self.CommonFuBenClear.gameObject:SetActiveEx(false)

        if XTool.IsNumberValid(self._StartLeftTime) then
            self.TxtUnlockTime.text = XUiHelper.FormatText(self._Control:GetClientConfigText('StageTimeLockTips'), XUiHelper.GetTime(self._StartLeftTime, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TxtUnlockTime.text = XUiHelper.FormatText(self._Control:GetClientConfigText('StageLockTips'), self._Control:GetStageNameById(self._PreStageId))
        end
    end
    
    self:RefreshStageState()
end

function XUiGridGame2048Stage:RefreshStageState()
    local curStageData = self._Control:GetCurStageData()
    self._IsOngoing = curStageData and curStageData.StageId == self._StageId
    self.PanelOngoing.gameObject:SetActiveEx(self._IsOngoing)
    self.BtnGiveUp.gameObject:SetActiveEx(self._IsOngoing)
    if self._UnLock then
        local curStageId = self._Control:GetCurStageId()
        local isSelect = XTool.IsNumberValid(curStageId) and curStageId == self._StageId
        self:SetSelectShow(isSelect)
        
        --- 正在进行的关卡暂时隐藏clear标记
        if self._IsOngoing then
            self.CommonFuBenClear.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridGame2048Stage:OnClickEvent()
    if self._UnLock then
        self.Parent:SetSelectStage(self)
    else
        local tips = ''
        if XTool.IsNumberValid(self._PreStageId) then
            tips = XUiHelper.FormatText(self._Control:GetClientConfigText('StageLockTips'), self._Control:GetStageNameById(self._PreStageId))
        else
            if XTool.IsNumberValid(self._StartLeftTime) then
                tips = XUiHelper.FormatText(self._Control:GetClientConfigText('StageTimeLockTips'), XUiHelper.GetTime(self._StartLeftTime, XUiHelper.TimeFormatType.ACTIVITY))
            else
                tips = self._Control:GetClientConfigText('NotInTimeCommonTips')
            end
        end
        XUiManager.TipMsg(tips)
    end
end

function XUiGridGame2048Stage:SetSelectShow(isShow)
    if self._UnLock then
        self.GridBtn:SetButtonState(isShow and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        if self.ImgSelect then
            self.ImgSelect.gameObject:SetActiveEx(isShow)
        end
    end
end

function XUiGridGame2048Stage:OnBtnGiveUpClick()
    if self._IsOngoing then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), self._Control:GetClientConfigText('GiveupTipsByHand'), nil, nil, function()
            self._Control:RequestGame2048GiveUp(function()
                self:Refresh()
            end)
        end)
    end
end

return XUiGridGame2048Stage