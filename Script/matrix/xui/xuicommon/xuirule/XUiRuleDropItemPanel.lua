--######################## XUiRuleProbabilityText ########################
local XUiRuleProbabilityText = XClass(nil, "XUiRuleProbabilityText")

function XUiRuleProbabilityText:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiRuleProbabilityText:SetData(name, probability)
    self.TxtName.text = name
    self.TxtProbability.text = string.format("%s%%", probability)
end

--######################## XUiRuleDropItemPanel ########################
local XUiRuleDropItemPanel = XClass(nil, "XUiRuleDropItemPanel")

local ChildType = {
    Good = 1,
    Probability = 2,
}

function XUiRuleDropItemPanel:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    -- XRuleDropItemViewModel
    self.RuleDropItemViewModel = nil
    self.RootUi = rootUi
    self.ItemTextNew.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
    self.PanelProbabilityTextNew.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
    self:RegisterUiEvents()
end

-- ruleDropItemViewModel : XRuleDropItemViewModel
function XUiRuleDropItemPanel:SetData(ruleDropItemViewModel)
    self.RuleDropItemViewModel = ruleDropItemViewModel
    self.TxtTitle.text = ruleDropItemViewModel:GetTitle()
    -- 切换按钮的名字
    self.BtnSwitch1:SetNameByGroup(0, ruleDropItemViewModel:GetProbabilityBtnName())
    self.BtnSwitch2:SetNameByGroup(0, ruleDropItemViewModel:GetGoodSwitchBtnName())
    -- 默认打开商品信息
    self:OnBtnSwitchGoodClicked()
    local content = CS.XGame.ClientConfig:GetString("HeroOffcialGachaWebsite")
    self.ItemTextNew.text = content
    self.PanelProbabilityTextNew.text = content
    self.ItemTextNew.HrefListener = function(link)
        self:ClickLink(link)
    end
    self.PanelProbabilityTextNew.HrefListener = function(link)
        self:ClickLink(link)
    end
end

--######################## 私有方法 ########################

function XUiRuleDropItemPanel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch1, self.OnBtnSwitchProbabilityClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch2, self.OnBtnSwitchGoodClicked)
end

function XUiRuleDropItemPanel:OnBtnSwitchProbabilityClicked()
    self:SwitchChildType(ChildType.Probability)
    self:RefreshProbabilities()
end

function XUiRuleDropItemPanel:OnBtnSwitchGoodClicked()
    self:SwitchChildType(ChildType.Good)
    self:RefreshGoods()
end

function XUiRuleDropItemPanel:RefreshGoods()
    if self.__initRefreshGoods then return end
    -- 遍历组
    local goodGroupDatas = self.RuleDropItemViewModel:GetGoodGroupDatas()
    local groupData, go
    for i = 1, #goodGroupDatas do
        groupData = goodGroupDatas[i]
        -- 创建组标题
        go = XUiHelper.Instantiate(self.TxtItemTitlePrefab.gameObject, self.PanelItemContent)
        go:GetComponent("Text").text = groupData.Title
        go.gameObject:SetActiveEx(true)
        -- 创建商品数据
        local itemContentGo = XUiHelper.Instantiate(self.PanelItemContentPrefab.gameObject, self.PanelItemContent)
        itemContentGo.gameObject:SetActiveEx(true)
        local goodDatas = groupData.GoodDatas
        XEntityHelper.SortItemDatas(goodDatas)
        for _, value in ipairs(goodDatas) do
            local itemGridGo = XUiHelper.Instantiate(self.ItemGridPrefab.gameObject, itemContentGo.transform)
            local gridCommon = XUiGridCommon.New(self.RootUi, itemGridGo)
            gridCommon:Refresh(value)
            gridCommon:SetName(string.format( "x%s", value.Count))
            itemGridGo.gameObject:SetActiveEx(true)
        end
    end
    self.__initRefreshGoods = true
end

function XUiRuleDropItemPanel:RefreshProbabilities()
    if self.__initRefreshProbabilities then return end
    local probabilityGroupDatas = self.RuleDropItemViewModel:GetProbabilityGroupDatas()
    local groupData, go
    for i = 1, #probabilityGroupDatas do
        groupData = probabilityGroupDatas[i]
        -- 创建组标题
        go = XUiHelper.Instantiate(self.TxtProbabilityTitlePrefab.gameObject, self.PanelProbabilityContent)
        go:GetComponent("Text").text = groupData.Title
        go.gameObject:SetActiveEx(true)
        -- 创建概率数据
        local probabilityContentGo = XUiHelper.Instantiate(self.PanelProbabilityConentPrefab.gameObject, self.PanelProbabilityContent)
        probabilityContentGo.gameObject:SetActiveEx(true)
        local probabilityDatas = groupData.ProbabilityDatas
        for _, value in ipairs(probabilityDatas) do
            local gridGo
            if value.IsSpecial then
                gridGo = XUiHelper.Instantiate(self.TextSpecialPrefab.gameObject, probabilityContentGo.transform)
            else
                gridGo = XUiHelper.Instantiate(self.TextNormalPrefab.gameObject, probabilityContentGo.transform)
            end
            gridGo.gameObject:SetActiveEx(true)
            local uiRuleProbabilityText = XUiRuleProbabilityText.New(gridGo)
            uiRuleProbabilityText:SetData(value.Name, value.Probability)
        end
    end
    self.__initRefreshProbabilities = true
end

function XUiRuleDropItemPanel:SwitchChildType(childType)
    self.BtnSwitch1.gameObject:SetActiveEx(childType == ChildType.Good)
    self.BtnSwitch2.gameObject:SetActiveEx(childType == ChildType.Probability)
    self.PanelItemList.gameObject:SetActiveEx(childType == ChildType.Good)
    self.PanelProbabilityList.gameObject:SetActiveEx(childType == ChildType.Probability)
end

function XUiRuleDropItemPanel:ClickLink(url)
    CS.UnityEngine.Application.OpenURL(url)
end

return XUiRuleDropItemPanel