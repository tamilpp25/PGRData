local XUiGridMoeWarNameplate = XClass(nil, "XUiGridMoeWarNameplate")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")

function XUiGridMoeWarNameplate:Ctor(ui, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.TxtCount.gameObject:SetActiveEx(false)
    self:InitCb()
end

function XUiGridMoeWarNameplate:InitCb()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end

function XUiGridMoeWarNameplate:Refresh(nameplateId)
    self.NameplateId = nameplateId
    if not XTool.IsNumberValid(self.NameplateId) then
        return
    end
    self.GoodsShowParams = self:GetGoodsShowParams()
    self.TxtName.text = XMoeWarConfig.GetNameplateItemName(self.NameplateId)
    if self.ImgCollection then
        self.ImgCollection:SetSprite(XMedalConfigs.GetNameplateQualityIcon(self.NameplateId))
    end
    if not self.PanelNameplate then
        local prefab = self.ImgHead.gameObject:LoadPrefab(XMedalConfigs.XNameplatePanelPath)
        self.PanelNameplate = XUiPanelNameplate.New(prefab, self.RootUi)
    end
    self.PanelNameplate.GameObject:SetActiveEx(true)
    self.PanelNameplate:UpdateDataById(self.NameplateId)
end

function XUiGridMoeWarNameplate:OnBtnClickClick()
    if not XTool.IsNumberValid(self.NameplateId) then
        return
    end
    XLuaUiManager.Open("UiNameplateTip", self.NameplateId, true, true, true)
end

function XUiGridMoeWarNameplate:GetGoodsShowParams()
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.NameplateId)
end

return XUiGridMoeWarNameplate