---@class XUiGuildWarTwinsClickBoard
local XUiGuildWarTwinsClickBoard = XClass(nil, "XUiGuildWarTwinsClickBoard")

function XUiGuildWarTwinsClickBoard:Ctor(ui, node, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.Node = node
    self:Init()
end
function XUiGuildWarTwinsClickBoard:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

function XUiGuildWarTwinsClickBoard:Show()
    self.GameObject:SetActiveEx(true)
    self:Update()
end

function XUiGuildWarTwinsClickBoard:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarTwinsClickBoard:Update()
    self:UpdateWeakness()
    self:UpdateHp()
    self:UpdateName()
end

function XUiGuildWarTwinsClickBoard:UpdateWeakness()
    local isHasWeakness = self.Node:HasWeakness()
    self.PanelRuodian.gameObject:SetActiveEx(isHasWeakness)
end

function XUiGuildWarTwinsClickBoard:UpdateHp()
    local hp = self.Node:GetHP()
    local maxHp = self.Node:GetMaxHP()
    self.TxtHP.text = string.format("%.1f", hp / 100) .. "%"
    self.Progress.fillAmount = hp / maxHp
    if hp == 0 then
        -- self.PanelHp.gameObject:SetActiveEx(false)
        self.PanelDeath.gameObject:SetActiveEx(true)
    else
        -- self.PanelHp.gameObject:SetActiveEx(true)
        self.PanelDeath.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarTwinsClickBoard:UpdateName()
    self.TxtName.text = self.Node:GetName(false)
    self.TxtNameEn.text = self.Node:GetNameEn(false)
end

function XUiGuildWarTwinsClickBoard:OnClick()
    
end

return XUiGuildWarTwinsClickBoard
