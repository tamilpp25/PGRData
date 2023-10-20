local XUiPanelQualityUp = XClass(nil, "XUiPanelQualityUp")

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0E70BDFF"),
    [false] = CS.UnityEngine.Color.gray,
}

function XUiPanelQualityUp:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelQualityUp:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePartnerInfo()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelQualityUp:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelQualityUp:UpdatePartnerInfo()
    local nextQuality = self.Data:GetQuality() + 1
    local icon = XMVCA.XCharacter:GetCharacterQualityIcon(nextQuality)
    self.TxtCurCount.text = self.Data:GetQualitySkillColumnCount()
    self.TxtNextCount.text = self.Data:GetQualitySkillColumnCount(nextQuality)
    self.RawImageQuality:SetRawImage(icon)
    local costMoney = self.Data:GetQualityEvolutionMoney().Count
    self.TxtCost.text = costMoney
    self.TxtCost.color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]
end

function XUiPanelQualityUp:SetButtonCallBack()
    self.BtnUpgrade.CallBack = function()
        self:OnBtnUpgradeClick()
    end
end

function XUiPanelQualityUp:OnBtnUpgradeClick()
    XDataCenter.PartnerManager.PartnerEvolutionRequest(self.Data:GetId(), function ()
            self.Base:SetQualityUpFinish(true)
            self.Base:UpdatePanel(self.Data)
    end)
end

return XUiPanelQualityUp