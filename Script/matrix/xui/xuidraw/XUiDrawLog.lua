local XUiDrawLog = XLuaUiManager.Register(XLuaUi, "UiDrawLog")
local BtnMaxCount = 4
local IndexEventRule = 4
local TypeText = {}
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString
local DrawLogLimit = CS.XGame.ClientConfig:GetInt("DrawLogLimit")
function XUiDrawLog:OnStart(drawInfo, selectIndex, cb)
    self.DrawId = drawInfo.Id
    self.DrawInfo = drawInfo
    self.SelectIndex = selectIndex
    if not self.SelectIndex then
        self.SelectIndex = 1
    end
    self.Cb = cb
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
    InitFunctionList = {
        function()
            self:InitBaseRulePanel()
        end,
        function()
            self:InitDrawPreview()
        end,
        function()
            self:InitDrawLogListPanel()
        end,
        function()
            self:InitEventRulePanel()
        end,
    }
    IsInit = {false, false, false, false }
    AnimeNames = { "QieHuanOne", "QieHuanTwo", "QieHuanThree", "QieHuanFour" }
    self:SetTypeText()
    self:InitBtnTab()
end

function XUiDrawLog:SetTypeText()
    TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XCharacterConfigs.GetCharacterType(templateId)
        if characterType == XCharacterConfigs.CharacterType.Normal then
            return CS.XTextManager.GetText("TypeCharacter")
        elseif characterType == XCharacterConfigs.CharacterType.Isomer then
            return CS.XTextManager.GetText("TypeIsomer")
        end
    end
    TypeText[XArrangeConfigs.Types.Weapon] = CS.XTextManager.GetText("TypeWeapon")
    TypeText[XArrangeConfigs.Types.Wafer] = CS.XTextManager.GetText("TypeWafer")
    TypeText[XArrangeConfigs.Types.Fashion] = CS.XTextManager.GetText("TypeFashion")
    TypeText[XArrangeConfigs.Types.Furniture] = CS.XTextManager.GetText("TypeFurniture")
    TypeText[XArrangeConfigs.Types.HeadPortrait] = CS.XTextManager.GetText("TypeHeadPortrait")
    TypeText[XArrangeConfigs.Types.ChatEmoji] = CS.XTextManager.GetText("TypeChatEmoji")
    TypeText[XArrangeConfigs.Types.Partner] = CS.XTextManager.GetText("TypePartner")
end

function XUiDrawLog:InitDrawLogListPanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local Rules = XDataCenter.DrawManager.GetDrawGroupRule(groupId)
    local name
    local quality
    local fromName
    local time
    local type

    local PanelObj = {}
    PanelObj.Transform = self.Panel3.transform
    XTool.InitUiObject(PanelObj)

    PanelObj.GridLogHigh.gameObject:SetActiveEx(false)
    PanelObj.GridLogMid.gameObject:SetActiveEx(false)
    PanelObj.GridLogLow.gameObject:SetActiveEx(false)
    PanelObj.TxtLogCount.text = CS.XTextManager.GetText("DrawLogCpunt", DrawLogLimit)
    if Rules.SpecialBottomMin > 0 and Rules.SpecialBottomMax > 0 then
        PanelObj.TxtEnsureCount.text = Rules.BottomText .. " " .. self.DrawInfo.BottomTimes .. "/(" .. Rules.SpecialBottomMin .. "~" .. Rules.SpecialBottomMax .. ")"
    else
        PanelObj.TxtEnsureCount.text = Rules.BottomText .. " " .. self.DrawInfo.BottomTimes .. "/" .. self.DrawInfo.MaxBottomTimes
    end
    for _, v in pairs(self.DrawInfo.HistoryRewardList) do
        if v.RewardGoods.ConvertFrom ~= 0 then
            local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.ConvertFrom)
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = fromGoods.Quality
            quality = quality or 1
            fromName = fromGoods.Name
            if fromGoods.TradeName then
                fromName = fromName .. "." .. fromGoods.TradeName
            end
            name = Goods.Name
            time = TimestampToGameDateTimeString(v.DrawTime)
            self:SetLogData(PanelObj, fromName, v.RewardGoods.ConvertFrom, name, time, quality)
        else
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = Goods.Quality
            quality = quality or 1
            name = Goods.Name
            if Goods.TradeName then
                name = name .. "." .. Goods.TradeName
            end
            time = TimestampToGameDateTimeString(v.DrawTime)
            self:SetLogData(PanelObj, name, v.RewardGoods.TemplateId, nil, time, quality)
        end
    end
end

function XUiDrawLog:SetLogData(obj, name, templateId, from, time, quality)
    local itemType = XArrangeConfigs.GetType(templateId)
    local go
    if itemType == XArrangeConfigs.Types.Character or itemType == XArrangeConfigs.Types.Partner then
        if quality >= XItemConfigs.Quality.Three then
            go = CS.UnityEngine.Object.Instantiate(obj.GridLogHigh, obj.PanelContent)
        else
            go = CS.UnityEngine.Object.Instantiate(obj.GridLogMid, obj.PanelContent)
        end
    else
        if quality == XItemConfigs.Quality.Six then
            go = CS.UnityEngine.Object.Instantiate(obj.GridLogHigh, obj.PanelContent)
        elseif quality == XItemConfigs.Quality.Five then
            go = CS.UnityEngine.Object.Instantiate(obj.GridLogMid, obj.PanelContent)
        else
            go = CS.UnityEngine.Object.Instantiate(obj.GridLogLow, obj.PanelContent)
        end
    end

    local tmpObj = {}
    tmpObj.Transform = go.transform
    tmpObj.GameObject = go.gameObject
    XTool.InitUiObject(tmpObj)
    tmpObj.TxtName.text = name
    
    if type(TypeText[itemType]) == "function" then
        tmpObj.TxtType.text = TypeText[itemType](templateId)
    else
        tmpObj.TxtType.text = TypeText[itemType]
    end
    
    if not from then
        tmpObj.TxtTo.gameObject:SetActiveEx(false)
    else
        tmpObj.TxtTo.text = CS.XTextManager.GetText("ToOtherThing", from)
    end
    tmpObj.TxtTime.text = time
    tmpObj.GameObject:SetActiveEx(true)
end

function XUiDrawLog:InitBaseRulePanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local baseRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).BaseRules
    local baseRuleTitles = XDataCenter.DrawManager.GetDrawGroupRule(groupId).BaseRuleTitles
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel1)
end

function XUiDrawLog:InitEventRulePanel()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local eventRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRules
    local eventRuleTitles = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRuleTitles
    self:SetRuleData(eventRules, eventRuleTitles, self.Panel4)
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
        tmpObj.TxtRule.supportRichText = true -- 解决需要配置空，二进制不兼容导致的问题(text支持富文本并且配置个富文本标签)
        tmpObj.TxtRule.text = rules[k]
        tmpObj.GameObject:SetActiveEx(true)
    end
end

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
    local upGoods = previewList.UpGoods
    local goods = previewList.Goods
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
        --日服定制化需求，概率可以跳转到网站查看更详细的概率
        tmpObj.TxtName.HrefListener = function(link, content)
            self:ClickLink(link)
        end
        tmpObj.GameObject:SetActiveEx(true)
        local str = list[i].Name
        tmpObj.TxtName.text = str
        --tmpObj.TxtName.text = list[i].Name
        tmpObj.TxtProbability.text = list[i].ProbShow
    end
    XScheduleManager.ScheduleOnce(function()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(PanelObj.PanelCardParent);
    end, 0)
end

function XUiDrawLog:InitBtnTab()
    local groupId = XDataCenter.DrawManager.GetDrawInfo(self.DrawId).GroupId
    local eventRules = XDataCenter.DrawManager.GetDrawGroupRule(groupId).EventRules

    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self.TabGroup[i] = self["BtnTab" .. i]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    if #eventRules > 0 then
        self.TabGroup[IndexEventRule].gameObject:SetActiveEx(true)
    else
        self.TabGroup[IndexEventRule].gameObject:SetActiveEx(false)
    end
    self.PanelTabTc:SelectIndex(self.SelectIndex)
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

function XUiDrawLog:OnSelectedTog(index)
    for i = 1, BtnMaxCount do
        self["Panel" .. i].gameObject:SetActiveEx(false)
    end

    self["Panel" .. index].gameObject:SetActiveEx(true)
    if not IsInit[index] then
        InitFunctionList[index]()
        IsInit[index] = true
    end

    self:PlayAnimation(AnimeNames[index])
end

function XUiDrawLog:ClickLink(url)
    CS.UnityEngine.Application.OpenURL(url)
end