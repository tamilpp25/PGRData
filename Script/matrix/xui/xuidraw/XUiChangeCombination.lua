local XUiChangeCombination = XLuaUiManager.Register(XLuaUi, "UiChangeCombination")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiChangeCombination:OnStart(drawId, count, IsChange, sureCb, closeCb)
    self.Count = count
    self.IsChange = IsChange
    self.SureCb = sureCb
    self.CloseCb = closeCb
    self:SetButtonCallBack()
    self:UpdatePanel(drawId)
end

function XUiChangeCombination:OnEnable()

end

function XUiChangeCombination:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    self.PaneCharacter:GetObject("BtnIconClick").CallBack = function()
        -- self:OnBtnIconClick()
    end
end

function XUiChangeCombination:OnBtnCloseClick()
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

function XUiChangeCombination:OnBtnConfirmClick()
    self:Close()
    if self.SureCb then self.SureCb(self.IsChange) end
end

function XUiChangeCombination:OnBtnIconClick()
    if self.CharId then
        self:Close()
        XLuaUiManager.Open("UiCharacterDetail", self.CharId)
    end
end

function XUiChangeCombination:UpdatePanel(drawId)
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
    if not combination then return end
    local goodsList = combination.GoodsId or {}
    local type = #goodsList > 0 and XArrangeConfigs.GetType(goodsList[1]) or XArrangeConfigs.Types.Error

    if type == XArrangeConfigs.Types.Character then
        self:SetCharacterData(combination)
    elseif type == XArrangeConfigs.Types.Error then
        self:SetBaseData(combination)
    end

    self.PaneCharacter.gameObject:SetActiveEx(type == XArrangeConfigs.Types.Character)
    self.PaneRandom.gameObject:SetActiveEx(type == XArrangeConfigs.Types.Error) 
    
    if self.IsChange then
        self.TxtInfo.text = CSTextManagerGetText("DrawSelectNormalHint", self.Count)
    else
        self.TxtInfo.text = CSTextManagerGetText("DrawSelectRandomHint")
    end
end

function XUiChangeCombination:SetCharacterData(combination)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])
    local quality = XCharacterConfigs.GetCharMinQuality(combination.GoodsId[1])
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()

    self.CharId = combination.GoodsId[1]
    self.PaneCharacter:GetObject("ImgBottomIcon"):SetRawImage(goodsShowParams.Icon)

    self.PaneCharacter:GetObject("TxtUp").text = drawAimProbability[combination.Id].UpProbability or ""
    self.PaneCharacter:GetObject("TxtUp").gameObject:SetActiveEx(drawAimProbability[combination.Id].UpProbability ~= nil)

    if goodsShowParams.Quality then
        local qualityIcon = goodsShowParams.QualityIcon or XArrangeConfigs.GeQualityPath(goodsShowParams.Quality)
        self.PaneCharacter:GetObject("ImgQuality"):SetSprite(qualityIcon)
    end
end

function XUiChangeCombination:SetBaseData(combination)
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    self.PaneRandom:GetObject("TxtUp").text = drawAimProbability[combination.Id].UpProbability or ""
    self.PaneRandom:GetObject("TxtUp").gameObject:SetActiveEx(drawAimProbability[combination.Id].UpProbability ~= nil)
end