local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiConsumeActivityLog = XLuaUiManager.Register(XLuaUi, "UiConsumeActivityLog")
local BtnMaxCount = 2
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}

function XUiConsumeActivityLog:OnStart(selectIndex)
    ---@type ConsumeDrawRuleEntity
    self.ConsumeDrawRule = XDataCenter.AccumulatedConsumeManager.GetConsumeDrawRule()
    self.SelectIndex = selectIndex or 1
    self:RegisterUiEvents()
    InitFunctionList = {
        function()
            self:InitDrawPreview()
        end,
        function()
            self:InitBaseRulePanel()
        end
    }
    IsInit = {false, false}
    AnimeNames = { "QieHuanOne", "QieHuanTwo"}
    self:InitBtnTab()
end

function XUiConsumeActivityLog:InitBtnTab()
    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self.TabGroup[i] = self[string.format("BtnTab%d", i)]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    self.PanelTabTc:SelectIndex(self.SelectIndex)
end

function XUiConsumeActivityLog:OnSelectedTog(index)
    for i = 1, BtnMaxCount do
        self[string.format("Panel%d", i)].gameObject:SetActiveEx(false)
    end

    self[string.format("Panel%d", index)].gameObject:SetActiveEx(true)
    if not IsInit[index] then
        InitFunctionList[index]()
        IsInit[index] = true
    end

    self:PlayAnimation(AnimeNames[index])
end

function XUiConsumeActivityLog:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnTanchuangClose)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnTanchuangClose)
end

function XUiConsumeActivityLog:InitDrawPreview()
    local PanelObj = {}
    PanelObj.Transform = self.Panel1.transform
    XTool.InitUiObject(PanelObj)
    
    PanelObj.Txtl01.gameObject:SetActiveEx(false)
    PanelObj.PanelTxtParent.gameObject:SetActiveEx(false)
    PanelObj.Line.gameObject:SetActiveEx(false)
    PanelObj.OrdinaryReward.gameObject:SetActiveEx(false)

    local rewardTypes = self.ConsumeDrawRule:GetRewardType()
    for i = 1, #rewardTypes do
        local rewardType = rewardTypes[i]
        local rewardTypeConfig = self.ConsumeDrawRule:GetRewardTypeConfig(rewardType)
        -- 标题
        local titleGo = CS.UnityEngine.Object.Instantiate(PanelObj.Txtl01, PanelObj.PanelDisView)
        local titleTxt = titleGo:GetComponent("Text")
        if titleTxt then
            titleTxt.text = rewardTypeConfig.RewardName
        end
        titleGo.gameObject:SetActiveEx(true)
        -- 内容
        local probShowList = self.ConsumeDrawRule:GetProbShow(rewardType)
        for _, probShow in pairs(probShowList) do
            local go = CS.UnityEngine.Object.Instantiate(PanelObj[rewardTypeConfig.PrefabName], PanelObj.PanelDisView)
            local txtUp = XUiHelper.TryGetComponent(go.transform,"TxtUp")
            local tmpObj = {}
            tmpObj.Transform = txtUp.transform
            tmpObj.GameObject = txtUp.gameObject
            XTool.InitUiObject(tmpObj)
            go.gameObject:SetActiveEx(true)

            if XTool.IsNumberValid(probShow.RewardId) and tmpObj.PanelProCard then
                local rewards = XRewardManager.GetRewardList(probShow.RewardId)
                if not XTool.IsTableEmpty(rewards) then
                    for index = 1, #rewards do
                        local panelProCard = index == 1 and tmpObj.PanelProCard or XUiHelper.Instantiate(tmpObj.PanelProCard, tmpObj.Transform)
                        local panel = XUiGridCommon.New(self.RootUi, panelProCard)
                        panel:Refresh(rewards[index])
                    end
                end
            end
            tmpObj.TxtName.text = probShow.Name
            tmpObj.TxtProbability.text = probShow.ProbShow
        end
        -- 下划线
        local Line = CS.UnityEngine.Object.Instantiate(PanelObj.Line, PanelObj.PanelDisView)
        Line.gameObject:SetActiveEx(true)
    end
    
    XScheduleManager.ScheduleOnce(function()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(PanelObj.PanelDisView);
    end, 0)
end

function XUiConsumeActivityLog:InitBaseRulePanel()
    local baseRules = self.ConsumeDrawRule:GetBaseRules()
    local baseRuleTitles = self.ConsumeDrawRule:GetBaseRuleTitles()
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel2)
end

function XUiConsumeActivityLog:SetRuleData(rules, ruleTitles, panel)
    local PanelObj = {}
    PanelObj.Transform = panel.transform
    XTool.InitUiObject(PanelObj)
    PanelObj.PanelTxt.gameObject:SetActiveEx(false)
    for k, _ in pairs(rules) do
        local go = CS.UnityEngine.Object.Instantiate(PanelObj.PanelTxt, PanelObj.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRuleTittle.text = ruleTitles[k]
        tmpObj.TxtRule.text = rules[k]
        tmpObj.GameObject:SetActiveEx(true)
    end
end

function XUiConsumeActivityLog:OnBtnTanchuangClose()
    self:Close()
end

return XUiConsumeActivityLog