---@class XUiGridLinkCraftActivityStage
---@field private _Control XLinkCraftActivityControl
---@field Parent XUiPanelLinkCraftActivityStage
local XUiGridLinkCraftActivityStage = XClass(XUiNode, 'XUiGridLinkCraftActivityStage')

function XUiGridLinkCraftActivityStage:OnStart(id,index)
    self._Id = id
    self._Index = index
    self._StageId = self._Control:GetStageIdById(self._Id)
    
    local stageTitle = XDataCenter.FubenManager.GetStageName(self._StageId)
    
    self.GridBtn:SetNameByGroup(0,stageTitle)
    self.GridBtn.CallBack = handler(self,self.OnBtnClickEvent)
    self.Transform.anchoredPosition = Vector2.zero
    
    -- 设置图片
    self.GridBtn:SetRawImage(self._Control:GetStageIconById(self._Id))
end

function XUiGridLinkCraftActivityStage:Refresh()
    self._IsPass = XMVCA.XLinkCraftActivity:CheckStageIsPassById(self._Id)
    self._IsUnLock = XMVCA.XLinkCraftActivity:CheckUnlockByStageId(self._StageId)

    if not self._IsUnLock then
        self:Close()
        return
    else
        self:Open()
    end
    
    self.GridBtn:SetButtonState(self._IsUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    
    --判断是否有技能奖励
    local skillId = self._Control:GetStageSkillRewardById(self._Id)
    local hasSkill = XTool.IsNumberValid(skillId)
    self.PanelSkill.gameObject:SetActiveEx(hasSkill)
    self.PanelAwarded.gameObject:SetActiveEx(hasSkill and self._IsPass)
    if hasSkill then
        self.RImgSkill:SetRawImage(self._Control:GetSkillIconById(skillId))
    end

    local fullStar = true
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self._StageId)
    local hasStarAim = XTool.GetTableCount(stageCfg.StarRewardId) > 0
    if hasStarAim then
        self.PanelStar.gameObject:SetActiveEx(true)
        --显示获得的星数
        local starCnt = self._Control:GetStageStarById(self._Id)
        fullStar = starCnt == 3
        for i = 1, 3 do
            local starOn = i <= starCnt
            if self['ImgOff'..i]  then
                self['ImgOff'..i].gameObject:SetActiveEx(not starOn)
            end

            if self['ImgOn'..i]  then
                self['ImgOn'..i].gameObject:SetActiveEx(starOn)
            end
        end
    else
        self.PanelStar.gameObject:SetActiveEx(false)
    end

    --显示困难关标记
    for i = 0, self.GridBtn.ImageList.Count -1 do
        if self.GridBtn.ImageList[i] then
            self.GridBtn.ImageList[i].gameObject:SetActiveEx(hasStarAim)
        end
    end
    
    --显示clear
    self.GridBtn:ShowTag(self._IsPass and fullStar)
end

function XUiGridLinkCraftActivityStage:OnBtnClickEvent()
    if not self._IsUnLock then
        XUiManager.TipMsg(self._Control:GetClientConfigString('StageUnLockTip'))
    else
        self:FocusUI()
        
        XLuaUiManager.Open('UiLinkCraftActivityChapterDetail',self._Id,self._Index)
    end
end

function XUiGridLinkCraftActivityStage:FocusUI()
    if self._IsUnLock == false then
        return
    end
    if self.Parent.CurGrid then
        self.Parent.CurGrid:UnFocusUI()
    end
    self.Parent.CurGrid = self
    --选中
    self.GridBtn:SetButtonState(CS.UiButtonState.Select)
end

function XUiGridLinkCraftActivityStage:UnFocusUI()
    self.GridBtn:SetButtonState(CS.UiButtonState.Normal)
end

return XUiGridLinkCraftActivityStage