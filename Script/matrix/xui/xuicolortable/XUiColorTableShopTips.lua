local XUiColorTableShopTips = XLuaUiManager.Register(XLuaUi, "UiColorTableShopTips")

function XUiColorTableShopTips:OnAwake()
    self:SetButtonCallBack()
    self:InitTimes()
end

function XUiColorTableShopTips:OnStart(desc)
    self.TxtMassage.text = desc
end

function XUiColorTableShopTips:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiColorTableShopTips:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
