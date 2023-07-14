local XUiDrawOptional = XLuaUiManager.Register(XLuaUi, "UiDrawOptional")
local combination = require("XUi/XUiDraw/XUiPanelCombination")
local CSTextManagerGetText = CS.XTextManager.GetText
local firstIndex = 1

function XUiDrawOptional:OnStart(parentUi, optionalCb, allTimeOverCb, currSelectDrawId)
    self.PanelCombinationHero.gameObject:SetActiveEx(false)
    self.PanelCombinationBase.gameObject:SetActiveEx(false)
    self.PanelCombination.gameObject:SetActiveEx(false)
    self.PanelCombinationPartner.gameObject:SetActiveEx(false)
    self.ParentUi = parentUi
    self.OptionalCb = optionalCb
    self.AllTimeOverCb = allTimeOverCb
    self.IsFirstIn = true
    self.CurSuitId = 0
    self.CurSelectDrawId = currSelectDrawId or 0
    self.HasNew = false
    self:AutoAddListener()
    self:SetData(self.ParentUi.GroupId)
end

function XUiDrawOptional:OnEnable()
    local defaultItem = self.Combinations[self.DefaultIndex]
    if defaultItem and (not self.HasNew) then
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
        local pos = self.SrollViewInfoList.transform:InverseTransformPoint(self.SrollViewInfoList.content.position) - self.SrollViewInfoList.transform:InverseTransformPoint(defaultItem.Transform.position)
        self.SrollViewInfoList.content.anchoredPosition = CS.UnityEngine.Vector2(pos.x, pos.y - 128)
    end
    self:PlayAnimation("UiDrawOptionalBegin")
end

function XUiDrawOptional:SetData(groupId)
    self.InfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(groupId)
    self.GroupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(groupId)

    local aimType = nil
    if not self.Combinations then
        self.Combinations = {}
    else
        for _, item in pairs(self.Combinations) do
            CS.UnityEngine.GameObject.Destroy(item)
        end
        self.Combinations = {}
    end

    local maxSwitchCount = self.GroupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = self.GroupInfo.SwitchDrawIdCount
    local IsCanSwitch = not self:IsHaveSwitchLimit() or maxSwitchCount > curSwitchCount
    self.PanelQieHuan.gameObject:SetActiveEx(maxSwitchCount > 0)
    if self:IsHaveSwitchLimit() then
        local count = maxSwitchCount - curSwitchCount
        self.TxtHaveCount.text = CSTextManagerGetText("DrawSelectCountFullText", count)
        self.TxtNotHaveCount.text = CSTextManagerGetText("DrawSelectNotCountFullText")
        self.TxtHaveCount.gameObject:SetActiveEx(count > 0)
        self.TxtNotHaveCount.gameObject:SetActiveEx(count <= 0)
    end

    for i = 1, #self.InfoList do
        if not XSaveTool.GetData(string.format("DrawOptionalNewDraw_%s_%s",XPlayer.Id,self.InfoList[i].Id)) then
            self.HasNew = true
            XSaveTool.SaveData(string.format("DrawOptionalNewDraw_%s_%s",XPlayer.Id,self.InfoList[i].Id),1)
        end
        if not self.Combinations[i] then
            local go
            local drawCt = XDataCenter.DrawManager.GetDrawCombination(self.InfoList[i].Id)
            local goodsList = drawCt.GoodsId or {}
            local goodsType = #goodsList > 0 and XArrangeConfigs.GetType(goodsList[1]) or XArrangeConfigs.Types.Error
            if goodsType == XArrangeConfigs.Types.Character then
                go = CS.UnityEngine.Object.Instantiate(self.PanelCombinationHero, self.PanelCombinationContent)
                aimType = goodsType
            elseif goodsType == XArrangeConfigs.Types.Partner then
                aimType = goodsType
                go = CS.UnityEngine.Object.Instantiate(self.PanelCombinationPartner, self.PanelCombinationContent)
            elseif goodsType == XArrangeConfigs.Types.Error then
                go = CS.UnityEngine.Object.Instantiate(self.PanelCombinationBase, self.PanelCombinationContent)
            else
                aimType = goodsType
                go = CS.UnityEngine.Object.Instantiate(self.PanelCombination, self.PanelCombinationContent)
            end

            local item = combination.New(go, self, i)
            table.insert(self.Combinations, item)
        end

        local IsDefaultDraw = false
        local id = self:IsHaveSwitchLimit() and self.GroupInfo.UseDrawId or self.ParentUi.DrawInfo.Id
        if self.InfoList[i].Id == id then
            self.DefaultIndex = i
            IsDefaultDraw = true
        end
        
        self.Combinations[i]:SetData(self.InfoList[i].Id, IsDefaultDraw, IsCanSwitch)
        self.Combinations[i]:SetActiveEx(true)
    end

    if aimType and aimType == XArrangeConfigs.Types.Character then
        self.TitleText.text = CSTextManagerGetText("AimCharacterSelectTitle")
    elseif aimType and aimType == XArrangeConfigs.Types.Weapon then
        self.TitleText.text = CSTextManagerGetText("AimEquipSelectTitle")
    elseif aimType and aimType == XArrangeConfigs.Types.Partner then
        self.TitleText.text = CSTextManagerGetText("AimPartnerSelectTitle")
    end

    for i = #self.InfoList + 1, #self.Combinations do
        self.Combinations[i]:SetActiveEx(false)
    end
    if self.DefaultIndex and self.Combinations[self.DefaultIndex] then
        self:SelectCombination(self.DefaultIndex, self.InfoList[self.DefaultIndex].Id)
    else
        if not self:IsHaveSwitchLimit() then
            self:SelectCombination(firstIndex, self.InfoList[firstIndex].Id)
        end
    end
end

function XUiDrawOptional:SelectCombination(index, drawId)
    if not index or not drawId then
        if self.SelectedIndex and self.Combinations[self.SelectedIndex] then
            self.Combinations[self.SelectedIndex]:SetSelectState(false)
        end
        self.SelectedIndex = nil
        self.CurSelectDrawId = 0
    else
        if self.Combinations[index] then
            if self.SelectedIndex and self.Combinations[self.SelectedIndex] then
                self.Combinations[self.SelectedIndex]:SetSelectState(false)
            end
            self.SelectedIndex = index
            self.Combinations[index]:SetSelectState(true)
            self.CurSelectDrawId = drawId
            if self.IsFirstIn then
                self.IsFirstIn = false
            else
               self.OptionalCb(self.CurSelectDrawId)
            end
        end
    end
end

function XUiDrawOptional:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

function XUiDrawOptional:AutoAddListener()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end
-- auto
function XUiDrawOptional:OnBtnCloseClick()
    local IsAllTimeOvel = true
    for _, info in pairs(self.InfoList) do
        if not XDataCenter.DrawManager.CheckDrawIsTimeOver(info.Id) then
            IsAllTimeOvel = false
            break
        end
    end
    if IsAllTimeOvel or self.CurSelectDrawId == 0 then
        self:Close()
        if self.AllTimeOverCb then
            self.AllTimeOverCb()
        end
        return
    end

    if XDataCenter.DrawManager.CheckDrawIsTimeOver(self.CurSelectDrawId) then
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end

    local sureFun = function(IsChange)
        self:Close()
        --self.ParentUi:PlaySpcalAnime()
        if IsChange then
            XDataCenter.DrawManager.SaveDrawAimId(self.CurSelectDrawId, self.ParentUi.GroupId, function()
                self.OptionalCb(self.CurSelectDrawId)
            end)
        end
    end

    local closeFun = function()
        local drawId = self.DefaultIndex and self.InfoList[self.DefaultIndex] and self.InfoList[self.DefaultIndex].Id
        self:SelectCombination(self.DefaultIndex, drawId)
    end

    local combination = XDataCenter.DrawManager.GetDrawCombination(self.CurSelectDrawId)
    local goodsList = combination and combination.GoodsId or {}
    local IsRandom = #goodsList == 0
    local maxSwitchCount = self.GroupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = self.GroupInfo.SwitchDrawIdCount
    local count = maxSwitchCount - curSwitchCount
    local IsChang = self.GroupInfo.UseDrawId ~= self.CurSelectDrawId
    if (IsChang or IsRandom) and maxSwitchCount > 0 then
        XLuaUiManager.Open("UiChangeCombination", self.CurSelectDrawId, count, IsChang, sureFun, closeFun)
    else
        sureFun(IsChang)
    end
end

function XUiDrawOptional:OnSuitGridClick(suitId)
    self.CurSuitId = suitId
    self.ParentUi:OpenChildUi("UiDrawSuitPreview", self.CurSuitId, self)
    --XLuaUiManager.Open("UiDrawSuitPreview", suitId)
end

function XUiDrawOptional:IsHaveSwitchLimit()
    return self.GroupInfo and self.GroupInfo.MaxSwitchDrawIdCount and self.GroupInfo.MaxSwitchDrawIdCount > 0
end