---@class XUiPanelTheatre3GeniusDetail : XUiNode
---@field _Control XTheatre3Control
local XUiPanelTheatre3GeniusDetail = XClass(XUiNode, "XUiPanelTheatre3GeniusDetail")

function XUiPanelTheatre3GeniusDetail:OnStart(callBack)
    self.CallBack = callBack
    self._Control:RegisterClickEvent(self, self.BtnUnlock, self.OnBtnUnlockClick)
    self.SkillPointOn = XTool.InitUiObjectByUi({}, self.PanelSkillPointOn)
    self.SkillPointOff = XTool.InitUiObjectByUi({}, self.PanelSkillPointOff)
end

function XUiPanelTheatre3GeniusDetail:Refresh(geniusId)
    self.GeniusId = geniusId
    -- 名称
    self.TxtName.text = self._Control:GetStrengthenTreeNameById(geniusId)
    -- 描述
    self.TxtDetails.text = self._Control:GetStrengthenTreeDescById(geniusId)
    -- 图片
    local icon = self._Control:GetStrengthenTreeIconById(geniusId)
    if self.RImgIcon and icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 物品
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.Theatre3TalentPoint)
    self.SkillPointOn.Icon:SetRawImage(itemIcon)
    self.SkillPointOff.Icon:SetRawImage(itemIcon)
    local needCount = self._Control:GetStrengthenTreeNeedPointById(geniusId)
    self.SkillPointOn.TxtCosumeNumber.text = needCount
    self.SkillPointOff.TxtCosumeNumber.text = needCount
    self:RefreshStatus()
    self:RefreshRedPoint()
end

function XUiPanelTheatre3GeniusDetail:RefreshStatus()
    -- 是否解锁（已激活）
    local isUnlock = self._Control:CheckStrengthTreeUnlock(self.GeniusId)
    -- 资源是否充足
    local isOn = self._Control:CheckStrengthenTreeNeedPointEnough(self.GeniusId)
    -- 是否开启
    local isOpen, desc = self._Control:CheckStrengthenTreeCondition(self.GeniusId)

    self.BtnUnlock.gameObject:SetActiveEx(isUnlock or isOpen)
    local isDisable = isUnlock or (isOpen and not isOn)
    self.BtnUnlock:SetDisable(isDisable)
    local btnIndex = 1
    if isUnlock then
        btnIndex = 2
    elseif isOpen then
        btnIndex = 3
    end
    self.BtnUnlock:SetNameByGroup(0, self._Control:GetClientConfig("StrengthenTreeBtnActiveName", btnIndex))
    self.SkillPointOn.GameObject:SetActiveEx(not isUnlock and isOpen and isOn)
    self.SkillPointOff.GameObject:SetActiveEx(not isUnlock and isOpen and not isOn)
    -- 显示解锁条件
    self.TxtCondition.gameObject:SetActiveEx(not isUnlock and not isOpen)
    self.TxtCondition.text = desc
end

function XUiPanelTheatre3GeniusDetail:RefreshRedPoint()
    -- 刷新红点
    local isRedPoint = self._Control:CheckStrengthenTreeRedPoint(self.GeniusId)
    self.BtnUnlock:ShowReddot(isRedPoint)
end

function XUiPanelTheatre3GeniusDetail:OnBtnUnlockClick()
    if self._Control:IsHaveAdventure() then
        XUiManager.TipMsg(self._Control:GetClientConfig("StrengthenTreeTips", 2))
        return
    end
    if not XTool.IsNumberValid(self.GeniusId) then
        return
    end
    -- 是否解锁（已激活）
    local isUnlock = self._Control:CheckStrengthTreeUnlock(self.GeniusId)
    if isUnlock then
        return
    end
    -- 前置天赋是否解锁
    local allUnlock = self._Control:CheckPreStrengthenTreeAllUnlock(self.GeniusId)
    if not allUnlock then
        XUiManager.TipMsg(self._Control:GetClientConfig("StrengthenTreeTips", 3))
        return
    end
    -- 货币是否充足
    local isEnough = self._Control:CheckStrengthenTreeNeedPointEnough(self.GeniusId)
    if not isEnough then
        XUiManager.TipMsg(self._Control:GetClientConfig("StrengthenTreeTips", 1))
        return
    end
    self._Control:ActivationStrengthenTreeRequest(self.GeniusId, function()
        self:RefreshStatus()
        self:RefreshRedPoint()
        if self.CallBack then
            self.CallBack()
        end
    end)
end

return XUiPanelTheatre3GeniusDetail