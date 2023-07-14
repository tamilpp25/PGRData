--强化详情窗口
local XUiSkillTipsPanel = XClass(nil, "XUiSkillTipsPanel")

local BtnActiveColor = {
    Disable = XUiHelper.Hexcolor2Color("FFFFFFFF"),
    Enable  = XUiHelper.Hexcolor2Color("F3CF54FF")
}
local CSVector2 = CS.UnityEngine.Vector2
local SIDE_OF_EDGE = {
    LEFT  = CSVector2(0, 0.5),
    RIGHT = CSVector2(1, 0.5)
}

function XUiSkillTipsPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)

    self.ImgIcon = self.ImgIcon or self.Transform:Find("ImgIcon"):GetComponent("RawImage")
    self.TxtDesc = self.TxtDesc or self.Transform:Find("TxtAttrInfo"):GetComponent("Text")
    self.BtnActive = self.BtnActive or self.Transform:Find("BtnActive"):GetComponent("XUiButton")
    self.TxtCount = self.TxtCount or self.Transform:Find("TxtCount"):GetComponent("Text")
    self.ItemIcon = self.ItemIcon or self.Transform:Find("ItemIcon"):GetComponent("RawImage")
    self.RImgDisable = self.BtnActive.transform:Find("Disable/RawImage"):GetComponent("RawImage")
    
    self.StrengthenCoinId = XBiancaTheatreConfigs.GetStrengthenCoinId()
    self.ItemIcon:SetRawImage(XItemConfigs.GetItemIconById(self.StrengthenCoinId))
    self.BtnActive.CallBack = function() 
        self:OnBtnActiveClick()
    end
end

function XUiSkillTipsPanel:Show(skillGrid)
    self.SkillGrid = skillGrid or self.SkillGrid
    local strengthenId = self.SkillGrid:GetStrengthenId()
    self.StrengthenId = strengthenId
    self:RefreshPanelSide()
    local isActive = XDataCenter.BiancaTheatreManager.IsBuyStrengthen(strengthenId)
    self.ImgIcon:SetRawImage(XBiancaTheatreConfigs.GetStrengthenIcon(strengthenId))
    self.TxtName.text = XBiancaTheatreConfigs.GetStrengthenName(strengthenId)
    self.TxtDesc.text = XBiancaTheatreConfigs.GetStrengthenDesc(strengthenId)
    self.TxtCount.gameObject:SetActiveEx(not isActive)
    self.ItemIcon.gameObject:SetActiveEx(not isActive)
    local count = XDataCenter.ItemManager.GetCount(XBiancaTheatreConfigs.TheatreOutCoin)
    local price = XBiancaTheatreConfigs.GetStrengthenUnlockPrice(strengthenId)
    self.TxtCount.text = price
    self.TxtCount.color = count >= price and XBiancaTheatreConfigs.GetTextColor(1) 
            or XBiancaTheatreConfigs.GetTextColor(2)
    
    local unlocked = XDataCenter.BiancaTheatreManager.CheckStrengthenUnlock(strengthenId)
    local isDisable = isActive or (not unlocked) 
    self.BtnActive:SetDisable(isDisable, not isDisable)
    local btnIndex = 1
    if isDisable then
        btnIndex = isActive and 2 or 1
        self.RImgDisable.gameObject:SetActiveEx(not isActive)
    else
        btnIndex = 3
    end
    self.BtnActive:SetNameByGroup(0, XBiancaTheatreConfigs.GetStrengthenBtnActiveName(btnIndex))
    self.GameObject:SetActiveEx(true)
end

function XUiSkillTipsPanel:RefreshPanelSide()
    --设置位置
    local pos = self.SkillGrid.Transform.localPosition
    local side
    if pos.x > 0 then
        side = SIDE_OF_EDGE.LEFT
    else
        side = SIDE_OF_EDGE.RIGHT
    end
    self.Transform.anchorMin = side
    self.Transform.anchorMax = side
    self.Transform.pivot     = side
    self.Transform.anchoredPosition = CSVector2.zero
end

function XUiSkillTipsPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiSkillTipsPanel:OnBtnActiveClick()
    local isAdventure = XDataCenter.BiancaTheatreManager.CheckHasAdventure()
    if isAdventure then
        XUiManager.TipMsg(XBiancaTheatreConfigs.GetBiancaTheatreStrengthenTips(1))
        return
    end
    XDataCenter.BiancaTheatreManager.RequestStrengthen(self.StrengthenId, function()
        self:Show(self.SkillGrid)
    end)
end

return XUiSkillTipsPanel