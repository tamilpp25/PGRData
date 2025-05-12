local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiDrawLog = XLuaUiManager.Register(XLuaUi, "UiDrawLog")
local BtnMaxCount = 5
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}
local INDEX = {
    EVENT_RULE = 3,
    ACTIVITY_TARGET = 4,
}

function XUiDrawLog:OnStart(drawInfo, selectIndex, cb)
    self.DrawId = drawInfo.Id
    self.DrawInfo = drawInfo
    self.SelectIndex = selectIndex or 1
    self.Cb = cb
    self:InitData()
    self:InitBtnTab()
    self:AddBtnListener()
end

function XUiDrawLog:OnEnable()
    self:AddEventListener()
end

function XUiDrawLog:OnDisable()
    self:RemoveEventListener()
end

--region Data & Obj
function XUiDrawLog:InitData()
    InitFunctionList = {
        function()
            self:InitBaseRulePanel()
        end,
        function()
            self:InitDrawPreview()
        end,
        function()
            self:InitEventRulePanel()
        end,
        function()
            self:InitActivityTargetPanel()
        end,
    }
    IsInit = {false, false, false, false }
    AnimeNames = { "QieHuanOne", "QieHuanTwo", "QieHuanThree", "QieHuanFour", "QieHuanFour" }
end

function XUiDrawLog:SetRuleData(rules, ruleTitles, panel)
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
--endregion

--region Ui - BaseRule
function XUiDrawLog:InitBaseRulePanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local baseRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).BaseRules
    local baseRuleTitles = XDataCenter.DrawManager.GetDrawGroupRule(groupId).BaseRuleTitles
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel1)
end
--endregion

--region Ui - DrawPreview
function XUiDrawLog:InitDrawPreview()
    local PanelObj = {}
    PanelObj.Transform = self.Panel2.transform
    XTool.InitUiObject(PanelObj)
    PanelObj.PanelProCard.gameObject:SetActiveEx(false)
    PanelObj.PanelStdCard.gameObject:SetActiveEx(false)
    PanelObj.TxtUp.gameObject:SetActiveEx(false)
    PanelObj.TxtNor.gameObject:SetActiveEx(false)

    local previewList = XDataCenter.DrawManager.GetDrawPreview(self.DrawId)
    if not previewList then
        return
    end
    
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.DrawInfo.GroupId)
    local drawGroupRule = XDrawConfigs.GetDrawGroupRuleById(self.DrawInfo.GroupId)
    local isNotSelectUp = drawGroupRule and drawGroupRule.IsNotSelectDefault and not XTool.IsNumberValid(groupInfo.UseDrawId)
    
    local upGoods = previewList.UpGoods
    local goods = previewList.Goods

    if isNotSelectUp then -- 没选Up的话不显示Up标志
        goods = XTool.MergeArray(upGoods, goods)
        upGoods = {}
    end
    
    for i = 1, #upGoods do
        local go = CS.UnityEngine.Object.Instantiate(PanelObj.PanelProCard, PanelObj.PanelCardParent)
        local item = XUiGridCommon.New(self, go)
        item:Refresh(upGoods[i])
    end

    for i = 1, #goods do
        local go = CS.UnityEngine.Object.Instantiate(PanelObj.PanelStdCard, PanelObj.PanelCardParent)
        local item = XUiGridCommon.New(self, go)
        item:Refresh(goods[i])
    end
    local list = XDataCenter.DrawManager.GetDrawProb(self.DrawId)
    if not list then
        return
    end
    for i = 1, #list do
        local go
        if list[i].IsUp then
            go = CS.UnityEngine.Object.Instantiate(PanelObj.TxtUp, PanelObj.PanelTxtParent)
        else
            go = CS.UnityEngine.Object.Instantiate(PanelObj.TxtNor, PanelObj.PanelTxtParent)
        end
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.GameObject:SetActiveEx(true)
        tmpObj.TxtName.text = list[i].Name
        tmpObj.TxtProbability.text = list[i].ProbShow
    end
    XScheduleManager.ScheduleOnce(function()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(PanelObj.PanelCardParent);
    end, 0)
end
--endregion

--region Ui - EventRulePanel
function XUiDrawLog:InitEventRulePanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local eventRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRules
    local eventRuleTitles = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRuleTitles
    self:SetRuleData(eventRules, eventRuleTitles, self.Panel3)
end

function XUiDrawLog:RefreshEventRulePanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local eventRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRules
    if XTool.IsTableEmpty(eventRules) then
        self.TabGroup[INDEX.EVENT_RULE].gameObject:SetActiveEx(false)
    else
        self.TabGroup[INDEX.EVENT_RULE].gameObject:SetActiveEx(true)
    end
end
--endregion

--region Ui - ActivityTargetPanel
function XUiDrawLog:_CreateActivityTargetPanel()
    if not self["BtnTab" .. INDEX.ACTIVITY_TARGET] then
        local btnGo = XUiHelper.Instantiate(self.BtnTab1.gameObject, self.BtnTab1.transform.parent)
        self["BtnTab" .. INDEX.ACTIVITY_TARGET] = XUiHelper.TryGetComponent(btnGo.transform, "", "XUiButton")
    end
    if not self["Panel" .. INDEX.ACTIVITY_TARGET] then
        local panelGo = XUiHelper.Instantiate(self.Panel1.gameObject, self.Panel1.transform.parent)
        self["Panel" .. INDEX.ACTIVITY_TARGET] = XUiHelper.TryGetComponent(panelGo.transform, "")
    end
end

function XUiDrawLog:InitActivityTargetPanel()
    local activityId = XDataCenter.DrawManager.GetDrawActivityTargetIdByGroupId(self.DrawInfo.GroupId)
    local baseRules = XDrawConfigs.GetDrawActivityTargetShowDescList(activityId)
    local baseRuleTitles = XDrawConfigs.GetDrawActivityTargetShowTitleList(activityId)
    self:SetRuleData(baseRules, baseRuleTitles, self["Panel" .. INDEX.ACTIVITY_TARGET])
end

function XUiDrawLog:RefreshActivityTargetPanel()
    local data = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(self.DrawInfo.GroupId)
    if data then
        self.TabGroup[INDEX.ACTIVITY_TARGET].gameObject:SetActiveEx(true)
        self.TabGroup[INDEX.ACTIVITY_TARGET]:SetNameByGroup(0, XDrawConfigs.GetDrawActivityTargetShowTabDesc(data:GetActivityId()))
    else
        self.TabGroup[INDEX.ACTIVITY_TARGET].gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - TabGroup
function XUiDrawLog:InitBtnTab()
    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self:_CreateActivityTargetPanel()
            self.TabGroup[i] = self["BtnTab" .. i]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    
    self:RefreshEventRulePanel()
    self:RefreshActivityTargetPanel()
    self.PanelTabTc:SelectIndex(self.SelectIndex)
end

function XUiDrawLog:OnSelectedTog(index)
    for i = 1, BtnMaxCount do
        if self["Panel" .. i] then
            self["Panel" .. i].gameObject:SetActiveEx(false)
        end
    end

    if not self["Panel" .. index] then
        return
    end
    self["Panel" .. index].gameObject:SetActiveEx(true)
    if not IsInit[index] then
        InitFunctionList[index]()
        IsInit[index] = true
    end
    self:PlayAnimation(AnimeNames[index])
end
--endregion

--region Ui - BtnListener
function XUiDrawLog:AddBtnListener()
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnSwitchOff.CallBack = function()
        self:OnBtnSwitchOff()
    end
    self.BtnSwitchOn.CallBack = function()
        self:OnBtnSwitchOn()
    end
end

function XUiDrawLog:OnBtnTanchuangClose()
    self:Close()
end

function XUiDrawLog:OnBtnSwitchOff()
    self.BtnSwitchOff.gameObject:SetActiveEx(false)
    self.BtnSwitchOn.gameObject:SetActiveEx(true)

    self.PanelTextView.gameObject:SetActiveEx(true)
    self.PanelDetailView.gameObject:SetActiveEx(false)

    self:PlayAnimation("TextViewQieHuan")
end

function XUiDrawLog:OnBtnSwitchOn()
    self.BtnSwitchOff.gameObject:SetActiveEx(true)
    self.BtnSwitchOn.gameObject:SetActiveEx(false)

    self.PanelTextView.gameObject:SetActiveEx(false)
    self.PanelDetailView.gameObject:SetActiveEx(true)

    self:PlayAnimation("DetailViewQieHuan")
end
--endregion

--region Event
function XUiDrawLog:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.Close, self)
end

function XUiDrawLog:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.Close, self)
end
--endregion