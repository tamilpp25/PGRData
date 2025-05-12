---@class XUiGridBagOrganizeStage: XUiNode
---@field _Control XBagOrganizeActivityControl
---@field Anim UnityEngine.Animator
local XUiGridBagOrganizeStage = XClass(XUiNode, 'XUiGridBagOrganizeStage')

function XUiGridBagOrganizeStage:OnStart(stageId, stageIndex)
    self._StageId = stageId
    self._StageIndex = stageIndex
    
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
end

function XUiGridBagOrganizeStage:OnEnable()
    self:_RandomPlayIdleAnim()
end

function XUiGridBagOrganizeStage:OnDisable()

end

function XUiGridBagOrganizeStage:_RandomPlayIdleAnim()
    if self.Anim then
        self.Anim:SetBool('idle', false)
        self.Anim:SetBool('idle2', false)
        -- 等权随机
        local num = CS.UnityEngine.Random.Range(0, 100)

        if num > 50 then
            self.Anim:SetBool('idle', true)
        else
            self.Anim:SetBool('idle2', true)
        end
    end
end

function XUiGridBagOrganizeStage:Refresh()
    self.GridBtn:SetNameByGroup(0, self._Control:GetStageNameById(self._StageId))
    
    self._UnLock, self._PreStageId = XMVCA.XBagOrganizeActivity:CheckUnlockByStageId(self._StageId)
    
    self.GridBtn:SetButtonState(self._UnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    local roleIcon = self._Control:GetStageEntranceRoleIconById(self._StageId)

    if not string.IsNilOrEmpty(roleIcon) then
        self.GridBtn:SetSprite(roleIcon)
    end
    
    if self.TxtScore then
        self.TxtScore.gameObject:SetActiveEx(self._UnLock)
    end

    if self.RImgRating then
        self.RImgRating.gameObject:SetActiveEx(self._UnLock)
    end

    if self._UnLock then
        local maxScore = self._Control:GetStageMaxScoreById(self._StageId)
        local hasScore = XTool.IsNumberValid(maxScore)

        if self.TxtScore then
            self.TxtScore.gameObject:SetActiveEx(hasScore)
        end
        
        self.CommonFuBenClear.gameObject:SetActiveEx(hasScore)

        if self.RImgRating then
            self.RImgRating.gameObject:SetActiveEx(hasScore)
        end
        
        if XTool.IsNumberValid(maxScore) then
            if self.TxtScore then
                self.TxtScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('BaseScoreLabel'), maxScore)
            end

            if self.RImgRating then
                self.RImgRating:SetRawImage(self._Control:GetScoreLevelIconByStageIdAndScore(self._StageId, maxScore))
            end
        end
    else
        self.CommonFuBenClear.gameObject:SetActiveEx(false)
    end
end

function XUiGridBagOrganizeStage:OnClickEvent()
    if self._UnLock then
        XMVCA.XBagOrganizeActivity:RequestBagOrganizeStart(self._StageId, function()
            self._Control:SetCurStageId(self._StageId)
            self._Control:StartGameInit()
            XLuaUiManager.Open('UiBagOrganizeGame', self._StageId)
        end)
    else
        local tips = XUiHelper.FormatText(self._Control:GetClientConfigText('StageLockTips'), self._Control:GetStageNameById(self._PreStageId))
        XUiManager.TipMsg(tips)
    end
end


return XUiGridBagOrganizeStage