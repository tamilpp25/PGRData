local XUiObtainNameplate = XLuaUiManager.Register(XLuaUi, "UiObtainNameplate")
local XUiGridNameplate = require("XUi/XUiNameplate/XUiGridNameplate")
function XUiObtainNameplate:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.GridPanelOne = XUiGridNameplate.New(self.PanelOneGrid, self)
    self.GridPanelTwo = XUiGridNameplate.New(self.PanelTwoGrid, self)
    self.GridPanelTwo2 = XUiGridNameplate.New(self.PanelTwoGridTwo, self)
    self.GridPanelOneThree = XUiGridNameplate.New(self.PanelOneThreeGrid, self)
    self.GridPanelFour = XUiGridNameplate.New(self.PanelFourGrid, self)
    self.GridPanelFour2 = XUiGridCommon.New(self, self.PanelFourGridProperty)
end

function XUiObtainNameplate:OnStart(data, lastData, itemId, itemCount)
    self.PanelOne.gameObject:SetActiveEx(false)
    self.PanelTwo.gameObject:SetActiveEx(false)
    self.PanelOneThree.gameObject:SetActiveEx(false)
    self.PanelFour.gameObject:SetActiveEx(false)
    if not lastData then
        if data:GetNameplateUpgradeType() == XMedalConfigs.NameplateGetType.TypeFour and itemId then
            self.PanelFour.gameObject:SetActiveEx(true)
            self:PlayAnimation("AnimEnable4")
            self.GridPanelFour:UpdateDataByGet(data)
            local itemData =  { TemplateId = itemId, Count = itemCount }
            self.GridPanelFour2:Refresh(itemData)
            
            self.PanelFourTxtTips.text = CS.XTextManager.GetText("NameplateToItemStr", XItemConfigs.GetItemNameById(itemId))
        else
            self.PanelOne.gameObject:SetActiveEx(true)
            self:PlayAnimation("AnimEnable1")
            self.GridPanelOne:UpdateDataByGet(data, true, false)
        end
    else
        if data:GetNameplateId() ~= lastData:GetNameplateId() then
            self.PanelTwo.gameObject:SetActiveEx(true)
            self:PlayAnimation("AnimEnable2")
            self.GridPanelTwo:UpdateDataByGet(lastData)
            self.GridPanelTwo2:UpdateDataByGet(data)
        else
            self.PanelOneThree.gameObject:SetActiveEx(true)
            self:PlayAnimation("AnimEnable3")
            self.GridPanelOneThree:UpdateDataByGet(data, true, true)
        end
    end
end

function XUiObtainNameplate:OnEnable()

end

function XUiObtainNameplate:OnDestroy()
    XDataCenter.MedalManager.OpenNextUiObtainNameplate()
end