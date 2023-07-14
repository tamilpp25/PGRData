local XUiPanelCombination = XClass(nil, "XUiPanelCombination")
local XUiGridSuitDetail = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitDetail")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelCombination:Ctor(ui, parent, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.Parent = parent
    self.Index = index
    self.TxtCombination.text = CS.XTextManager.GetText("DrawCombination", index)
end

function XUiPanelCombination:SetData(drawId, IsDefaultDraw, IsCanSwitch)
    local clickCb = function(data, grid)
        self.Parent:OnSuitGridClick(data, grid)
    end

    if self.DrawId ~= drawId then
        self.DrawId = drawId
        local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
        if not combination then return end
        local goodsList = combination.GoodsId or {}
        self.Type = #goodsList > 0 and XArrangeConfigs.GetType(goodsList[1]) or XArrangeConfigs.Types.Error

        local list = combination.GoodsId
        if not self.Compositions then
            self.Compositions = {}
        end

        if self.Type == XArrangeConfigs.Types.Character then
            self:SetCharacterData(combination)
        elseif self.Type == XArrangeConfigs.Types.Partner then
            self:SetPartnerData(combination, list)
        elseif self.Type ~= XArrangeConfigs.Types.Error then
            self:SetEquipData(combination, list, clickCb)
        else
            self:SetBaseData()
        end
    end

    self:SetSelectState(false)
    self:SetPanelSwitch(IsDefaultDraw, IsCanSwitch)
    self:SetActiveEx(true)

    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    local drawInfo = XDataCenter.DrawManager.GetDrawInfo(self.DrawId)
    local nowTime = XTime.GetServerNowTimestamp()

    if self.TxtTitle then
        if drawInfo.EndTime - nowTime > 0 then
            self.TxtTitle.text = CSTextManagerGetText("DrawAimLeftTime", XUiHelper.GetTime(drawInfo.EndTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TxtTitle.text = CSTextManagerGetText("DrawAimLeftTimeOver")
        end
        self.TxtTitle.gameObject:SetActiveEx(drawInfo.EndTime > 0)
    end

    self.UpTip.gameObject:SetActiveEx(drawInfo.EndTime > 0)

    if self.TxtCount then
        self.TxtCount.gameObject:SetActiveEx(false)
        if drawAimProbability[self.DrawId] then
            self.TxtCount.text = drawAimProbability[self.DrawId].UpProbability or ""
            self.TxtCount.gameObject:SetActiveEx(drawAimProbability[self.DrawId].UpProbability ~= nil)
        end
    end

    self.Probability.gameObject:SetActiveEx(true)
end

function XUiPanelCombination:SetEquipData(combination, list, clickCb)
    self.PanelComposition.gameObject:SetActiveEx(false)
    self.PanelSuitCommon.gameObject:SetActiveEx(false)

    for _, v in pairs(self.Compositions) do
        CS.UnityEngine.Object.Destroy(v.GameObject)
    end
    self.Compositions = {}
    for i = 1, #list do
        if not self.Compositions[i] then
            local go
            if combination.Type == XDrawConfigs.CombinationsTypes.Aim then
                go = CS.UnityEngine.Object.Instantiate(self.PanelComposition, self.PanelNormal)
                local item = XUiGridCommon.New(self.Parent, go)
                item.GameObject:SetActiveEx(true)
                table.insert(self.Compositions, item)
            elseif combination.Type == XDrawConfigs.CombinationsTypes.EquipSuit then
                go = CS.UnityEngine.Object.Instantiate(self.PanelSuitCommon, self.PanelSuit)
                local item = XUiGridSuitDetail.New(go, self.Parent, clickCb)
                item.GameObject:SetActiveEx(true)
                table.insert(self.Compositions, item)
            end
        end
        self.Compositions[i]:Refresh(list[i], nil, true)
    end

    if self.InfectTip then
        local IsIsomer = false
        for _,composition in pairs(self.Compositions) do
            local templateData = XEquipConfig.GetEquipCfg(composition.TemplateId)
            if templateData.CharacterType == XEquipConfig.UserType.Isomer then
                IsIsomer = true
                break 
            end
        end
        
        self.InfectTip.gameObject:SetActiveEx(IsIsomer)
    end
end

function XUiPanelCombination:SetPartnerData(combination, list)
    self.PanelComposition.gameObject:SetActiveEx(false)

    for _, v in pairs(self.Compositions) do
        CS.UnityEngine.Object.Destroy(v.GameObject)
    end

    self.Compositions = {}
    for i = 1, #list do
        if not self.Compositions[i] then
            local go
            if combination.Type == XDrawConfigs.CombinationsTypes.Aim then
                go = CS.UnityEngine.Object.Instantiate(self.PanelComposition, self.PanelNormal)
                local item = XUiGridCommon.New(self.Parent, go)
                item.GameObject:SetActiveEx(true)
                table.insert(self.Compositions, item)
            end
        end
        self.Compositions[i]:Refresh(list[i], nil, true)
    end
end

function XUiPanelCombination:SetCharacterData(combination)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])
    local quality = XCharacterConfigs.GetCharMinQuality(combination.GoodsId[1])

    self.CharId = combination.GoodsId[1]
    self.AimImgBottomIco:SetRawImage(goodsShowParams.Icon)
    self.AimImgBottomRank:SetRawImage(XCharacterConfigs.GetCharQualityIcon(quality))

    if goodsShowParams.Quality then
        local qualityIcon = goodsShowParams.QualityIcon

        if qualityIcon then
            self.Parent:SetUiSprite(self.AimImgQuality, qualityIcon)
        else
            XUiHelper.SetQualityIcon(self.Parent, self.AimImgQuality, goodsShowParams.Quality)
        end
    end
end

function XUiPanelCombination:SetBaseData()
    --self.Probability.gameObject:SetActiveEx(false)
    --local drawInfo = XDataCenter.DrawManager.GetDrawInfo(self.DrawId)
    --self.TxtCount.text = string.format("%d/%d",drawInfo.BottomTimes,drawInfo.MaxBottomTimes)
end

function XUiPanelCombination:SetPanelSwitch(IsDefaultDraw, IsCanSwitch)
    if not IsDefaultDraw and not IsCanSwitch then
        if self.BtnSelect then
            self.BtnSelect.gameObject:SetActiveEx(false)
        end
        if self.TxtSelected then
            self.TxtSelected.gameObject:SetActiveEx(false)
        end
        if self.PanelCanNotSelect then
            self.PanelCanNotSelect.gameObject:SetActiveEx(true)
        end
    else
        if self.PanelCanNotSelect then
            self.PanelCanNotSelect.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelCombination:SetSelectState(bool)

    self.BtnSelect.gameObject:SetActiveEx(not bool)
    self.TxtSelected.gameObject:SetActiveEx(bool)

    if self.Type == XArrangeConfigs.Types.Character then
        self.Up.gameObject:SetActiveEx(bool)
    elseif self.Type ~= XArrangeConfigs.Types.Error then
        if not self.Compositions then
            return
        end
        for _, v in pairs(self.Compositions) do
            v:SetShowUp(bool)
        end
    end
end

function XUiPanelCombination:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

function XUiPanelCombination:AutoAddListener()
    self.BtnSelect.CallBack = function() self:OnBtnSelectClick() end

    if self.BtnClick then
        self.BtnClick.CallBack = function()
            self:OnBtnClickClick()
        end
    end
end
-- auto
function XUiPanelCombination:OnBtnSelectClick()
    self.Parent:SelectCombination(self.Index, self.DrawId)
    --CS.XUiManager.ViewManager:Pop()
end

function XUiPanelCombination:OnBtnClickClick()
    if self.Type == XArrangeConfigs.Types.Character then
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", self.CharId)
    end
end

return XUiPanelCombination