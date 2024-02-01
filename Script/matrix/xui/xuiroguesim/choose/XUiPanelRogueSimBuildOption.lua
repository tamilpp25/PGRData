---@class XUiPanelRogueSimBuildOption : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimChoose
local XUiPanelRogueSimBuildOption = XClass(XUiNode, "XUiPanelRogueSimBuildOption")

function XUiPanelRogueSimBuildOption:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

---@param id number 建筑自增Id
function XUiPanelRogueSimBuildOption:Refresh(id)
    self.Id = id
    self.BuildId = self._Control.MapSubControl:GetBuildingConfigIdById(id)
    self.IsBuy = self._Control.MapSubControl:CheckBuildingIsBuyById(id)
    self:RefreshGridBuild()
    self:RefreshStatus()
end

function XUiPanelRogueSimBuildOption:RefreshGridBuild()
    if not self.SingleGridBuild then
        ---@type XUiGridRogueSimBuild
        self.SingleGridBuild = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild").New(self.GridBuild, self)
    end
    self.SingleGridBuild:Open()
    self.SingleGridBuild:Refresh(self.Id)
    self.SingleGridBuild:SetProfitActive(not self.IsBuy)
end

function XUiPanelRogueSimBuildOption:RefreshStatus()
    if not self.IsBuy then
        -- 检查金币是否充足
        local isEnough = self._Control.MapSubControl:CheckBuyBuildingGoldIsEnough(self.BuildId)
        self.TxtTips.gameObject:SetActiveEx(not isEnough)
        self.BtnBuy:SetDisable(not isEnough)
    else
        self.TxtTips.gameObject:SetActiveEx(false)
        self.BtnBuy.gameObject:SetActiveEx(false)
    end
end

function XUiPanelRogueSimBuildOption:OnBtnBuyClick()
    if self.IsBuy then
        return
    end
    local isEnough = self._Control.MapSubControl:CheckBuyBuildingGoldIsEnough(self.BuildId)
    if not isEnough then
        XUiManager.TipMsg(self._Control:GetClientConfig("BuyBuildingGoldNotEnough"))
        return
    end
    self._Control:RogueSimBuildingBuyRequest(self.Id, function()
        self._Control:BuyBuildingAfter(self.BuildId)
        self.Parent:Close()
    end)
end

function XUiPanelRogueSimBuildOption:OnBtnBackClick()
    self.Parent:Close()
end

return XUiPanelRogueSimBuildOption
