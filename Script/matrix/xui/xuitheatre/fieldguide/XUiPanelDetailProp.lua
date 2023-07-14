--信物和道具详情的布局
local XUiPanelDetailProp = XClass(nil, "XUiPanelDetailProp")

function XUiPanelDetailProp:Ctor(ui, isShowUseBtn, selectTokenCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.IsShowUseBtn = isShowUseBtn
    self.SelectTokenCb = selectTokenCb  --选择信物回调
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()

    self.BtnGo:SetName(CsXTextManagerGetText("TheatreUse"))
    self:SetButtonCallBack()
end

function XUiPanelDetailProp:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
end

-- token : XAdventureToken
function XUiPanelDetailProp:Show(token)
    self.Token = token

    local id = token:GetId()
    self.TxtEffectInfo.text = XUiHelper.ConvertLineBreakSymbol(token:GetDescription())
    self.TxtWayInfo.text = XUiHelper.ConvertLineBreakSymbol(token:GetExplain())

    local fightCountConfig = XTheatreConfigs.GetTheatreItemFightCount(id)
    local fightCount = token:GetFightCount()
    local isHaveFightCount = XTool.IsNumberValid(fightCountConfig)
    local conditionInfo = isHaveFightCount and XUiHelper.GetText("TheatreTokenLevelUpConditionDesc", fightCount, fightCountConfig) or ""
    self.TxtConditionInfo.text = XUiHelper.ConvertLineBreakSymbol(conditionInfo)
    self.PanelCondition.gameObject:SetActiveEx(isHaveFightCount)

    local isToken = XTheatreConfigs.GetTheatreItemType(token:GetId()) == XTheatreConfigs.ItemType.Token
    self.BtnGo.gameObject:SetActiveEx((self.IsShowUseBtn and isToken) and true or false)
end

function XUiPanelDetailProp:OnBtnGoClick()
    if self.SelectTokenCb then
        self.SelectTokenCb(self.Token)
        XLuaUiManager.Close("UiTheatreFieldGuide")
    end
    -- self.AdventureManager:UpdateCurrentToken(self.Token)
end

return XUiPanelDetailProp