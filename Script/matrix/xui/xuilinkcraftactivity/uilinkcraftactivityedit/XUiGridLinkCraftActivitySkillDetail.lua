---编辑界面右边列表的技能格子
---@class XUiGridLinkCraftActivitySkillDetail
---@field private _Control XLinkCraftActivityControl
local XUiGridLinkCraftActivitySkillDetail = XClass(XUiNode, 'XUiGridLinkCraftActivitySkillDetail')

function XUiGridLinkCraftActivitySkillDetail:OnStart()
    self:Init()
    self:PlayAnimation('GridLinkSkillEnable')
end

function XUiGridLinkCraftActivitySkillDetail:Init()
    self.BtnEnterB.CallBack = handler(self,self.OnBtnEnterClickEvent)
end

function XUiGridLinkCraftActivitySkillDetail:SetSkillId(skillId)
    self._SkillId = skillId
    self:Refresh()
end

function XUiGridLinkCraftActivitySkillDetail:Refresh()
    self.TxtName.text = self._Control:GetSkillNameById(self._SkillId)
    self.TxtDetail.text = self._Control:GetSkillDetailById(self._SkillId)
    self.TxtTips.text = self._Control:GetSkillTypeTextByid(self._SkillId)
    self.RImgSkill:SetRawImage(self._Control:GetSkillIconById(self._SkillId))
    self._IsLock = self._Control:CheckSkillIsLockById(self._SkillId)

    self._IsUsing = false
    self._UsingIndex = 0
    
    if not self._IsLock then
        self._IsUsing, self._UsingIndex = self._Control:CheckSkillIsUsingById(self._SkillId)
    end
    
    self.PanelNum.gameObject:SetActiveEx(self._IsUsing or false)

    if self._IsLock then
        local unlockTips = self._Control:GetSkillUnlockTips(self._SkillId)
        if not string.IsNilOrEmpty(unlockTips) then
            self.BtnEnterB:SetNameByGroup(1,unlockTips)
        end
        self.BtnEnterB:SetButtonState(CS.UiButtonState.Disable)
    elseif self._IsUsing then
        self.TxtNum.text = self._UsingIndex
        -- 如果当前在链条中选中的位置和这个技能所在的位置相同，则显示佩戴中. 否则更改交互文本为‘替换’
        if self._UsingIndex == self._Control:GetSelectIndex() then
            self.BtnEnterB:SetButtonState(CS.UiButtonState.Select)
        else
            self.BtnEnterB:SetButtonState(CS.UiButtonState.Normal)
            self.BtnEnterB:SetNameByGroup(0,self._Control:GetClientConfigString('EditSkillSwitch'))
        end
    else
        self.BtnEnterB:SetButtonState(CS.UiButtonState.Normal)
        self.BtnEnterB:SetNameByGroup(0,self._Control:GetClientConfigString('EditSkillUse'))
    end
end

function XUiGridLinkCraftActivitySkillDetail:OnBtnEnterClickEvent()
    if self._IsLock then
        
    elseif self._IsUsing and self._UsingIndex == self._Control:GetSelectIndex() then
        self.BtnEnterB:SetButtonState(CS.UiButtonState.Select)
        XUiManager.TipMsg(self._Control:GetClientConfigString('TipsSkillHadUsed'))
    else
        if self._IsUsing then
            --交换位置
            self._Control:SwitchSkillIntoCurSelect(self._SkillId)
        else
            self._Control:SetSkillIntoCurSelect(self._SkillId)
        end
        
        self._Control:SetIsEditLink(true)
        self.Parent:Refresh()
        self.Parent:RefreshLinkSkill()
        XUiManager.TipMsg(self._Control:GetClientConfigString('LinkSkillWearSuccessTips'))
    end
end

return XUiGridLinkCraftActivitySkillDetail