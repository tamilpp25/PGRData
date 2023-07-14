local XUiDiviningLog = XLuaUiManager.Register(XLuaUi, "UiDiviningLog")
local BtnMaxCount = 2
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}

function XUiDiviningLog:OnStart(id)
    self.Id = id
    self.SelectIndex = 1
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end

    InitFunctionList = {
        function ()
            self:InitBaseRulePanel()
        end,
        function ()
            self:InitDrawLogListPanel()
        end,
    }
    IsInit = {false,false}

    AnimeNames = {"QieHuanOne","QieHuanThree"}
    self:InitBtnTab()
end

function XUiDiviningLog:InitDrawLogListPanel()
    local PanelObj = {}
    PanelObj.Transform = self.Panel2.transform
    XTool.InitUiObject(PanelObj)

    PanelObj.GridLogLow.gameObject:SetActiveEx(false)
    local records = XDataCenter.SignInManager.GetAllDiviningDatas()
    for k, v in pairs(records) do
        local diviningCfg = XSignInConfigs.GetDiviningSignRewardConfig(v.DailyLotteryRewardId)
        local signName = diviningCfg.RewardSignDesc
        local strItemsDesc = ""
        local rewards = XRewardManager.GetRewardList(diviningCfg.RewardId)
        if rewards then
            for i = 1, #rewards do
                local count = rewards[i].Count
                local name = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(rewards[i].TemplateId).Name
                if i < #rewards then
                    strItemsDesc = string.format("%s%s%s%d%s", strItemsDesc, name, "*", count, "， ")
                else
                    strItemsDesc = string.format("%s%s%s%d", strItemsDesc, name, "*", count)
                end
            end
        end

        local time = XTime.TimestampToGameDateTimeString(v.Time, "yyyy-MM-dd HH:mm")
        self:SetLogData(PanelObj, signName, strItemsDesc, time)
    end
end

function XUiDiviningLog:SetLogData(obj, name, itemsDesc, time)
    local go = {}
    go = CS.UnityEngine.Object.Instantiate(obj.GridLogLow, obj.PanelContent)

    local tmpObj = {}
    tmpObj.Transform = go.transform
    tmpObj.GameObject = go.gameObject
    XTool.InitUiObject(tmpObj)
    tmpObj.TxtName.text = name
    tmpObj.TxtItems.text = itemsDesc
    tmpObj.TxtTime.text = time
    tmpObj.GameObject:SetActiveEx(true)
end

function XUiDiviningLog:InitBaseRulePanel()
    local cfg = XSignInConfigs.GetNewYearSignInConfig(self.Id)
    local baseRules = cfg.RuleTitle
    local baseRuleTitles = cfg.RuleContent
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel1)
end

function XUiDiviningLog:SetRuleData(rules, ruleTitles, panel)
    local PanelObj = {}
    PanelObj.Transform = panel.transform
    XTool.InitUiObject(PanelObj)
    PanelObj.PanelTxt.gameObject:SetActiveEx(false)
    for k,v in pairs(rules) do
        local go = CS.UnityEngine.Object.Instantiate(PanelObj.PanelTxt, PanelObj.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRuleTittle.text = ruleTitles[k]
        tmpObj.TxtRule.text = rules[k]
        tmpObj.TxtRuleTittle.text = string.gsub(tmpObj.TxtRuleTittle.text, "\\n", "\n")
        tmpObj.TxtRule.text = string.gsub(tmpObj.TxtRule.text, "\\n", "\n")
        tmpObj.GameObject:SetActiveEx(true)
    end
end

function XUiDiviningLog:InitBtnTab()
    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self.TabGroup[i] = self["BtnTab"..i]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    self.PanelTabTc:SelectIndex(self.SelectIndex)
end

function XUiDiviningLog:OnBtnTanchuangClose()
    self:Close()
end

function XUiDiviningLog:OnSelectedTog(index)
    for i = 1, BtnMaxCount do
        self["Panel"..i].gameObject:SetActiveEx(false)
    end

    self["Panel"..index].gameObject:SetActiveEx(true)
    if not IsInit[index] then
        InitFunctionList[index]()
        IsInit[index] = true
    end

    self:PlayAnimation(AnimeNames[index])
end