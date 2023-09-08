local XUiDrawActivityLog = XLuaUiManager.Register(XLuaUi, "UiDrawActivityLog")
local BtnMaxCount = 3
local ProbMax = 5
local TypeText = {}
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString
local DrawLogLimit = CS.XGame.ClientConfig:GetInt("DrawLogLimit")
function XUiDrawActivityLog:OnStart(gachaId, selectIndex, organizeRule)
    self.GachaId = gachaId
    self.SelectIndex = selectIndex or 1
    self.OrganizeRule = organizeRule
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnTanchuangClose()
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
    }
    IsInit = {false, false, false, false }
    AnimeNames = { "QieHuanOne", "QieHuanTwo", "QieHuanThree", "QieHuanFour" }
    self:SetTypeText()
    self:InitBtnTab()
end

function XUiDrawActivityLog:SetTypeText()
    TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XMVCA.XCharacter:GetCharacterType(templateId)
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
end

function XUiDrawActivityLog:InitDrawLogListPanel()
    local Rules = self.OrganizeRule or XGachaConfigs.GetGachaRuleCfgById(self.GachaId)
    local gachaLogList = XDataCenter.GachaManager.GetGachaLogById(self.GachaId)
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
    PanelObj.TxtEnsureCount.gameObject:SetActiveEx(false)--此处在加上逻辑以后改为根据是否抽干有限道具判断
    PanelObj.TxtLogCount.text = CS.XTextManager.GetText("DrawLogCpunt", DrawLogLimit)
    --if Rules.SpecialBottomMin > 0 and Rules.SpecialBottomMax > 0 then
    --    PanelObj.TxtEnsureCount.text = Rules.BottomText .. " " .. self.DrawInfo.BottomTimes .. "/(" .. Rules.SpecialBottomMin .. "~" .. Rules.SpecialBottomMax .. ")"
    --else
    --    PanelObj.TxtEnsureCount.text = Rules.BottomText .. " " .. self.DrawInfo.BottomTimes .. "/" .. self.DrawInfo.MaxBottomTimes
    --end
    
    for _, v in pairs(gachaLogList) do
        if v.RewardGoods.ConvertFrom ~= 0 then
            local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.ConvertFrom)
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = fromGoods.Quality
            quality = quality or 1
            fromName = fromGoods.Name
            if fromGoods.TradeName then
                fromName =  string.format("%s.%s", fromName,fromGoods.TradeName)
            end
            name = Goods.Name
            time = TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(PanelObj, fromName, v.RewardGoods.ConvertFrom, name, time, quality)
        else
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = Goods.Quality
            quality = quality or 1
            name = Goods.Name
            if Goods.TradeName then
                name = string.format("%s.%s", name,Goods.TradeName)
            end
            time = TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(PanelObj, name, v.RewardGoods.TemplateId, nil, time, quality)
        end
    end
end

function XUiDrawActivityLog:SetLogData(obj, name, templateId, from, time, quality)
    local itemType = XArrangeConfigs.GetType(templateId)
    local go
    if itemType == XArrangeConfigs.Types.Character then
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

function XUiDrawActivityLog:InitBaseRulePanel()
    local rule = self.OrganizeRule or XGachaConfigs.GetGachaRuleCfgById(self.GachaId)
    local baseRules = rule.BaseRules
    local baseRuleTitles = rule.BaseRuleTitles
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel1)
end

function XUiDrawActivityLog:SetRuleData(rules, ruleTitles, panel)
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

function XUiDrawActivityLog:InitDrawPreview()
    local PanelObj = {}
    PanelObj.Transform = self.Panel2.transform
    XTool.InitUiObject(PanelObj)

    PanelObj.TxtSp.gameObject:SetActiveEx(false)
    PanelObj.TxtNor.gameObject:SetActiveEx(false)
    
    local list = XDataCenter.GachaManager.GetGachaProbShowById(self.GachaId)
    if not list then
        return
    end
    for i = 1, #list do
        local go
        if list[i].IsRare then
            go = CS.UnityEngine.Object.Instantiate(PanelObj.TxtSp, PanelObj.PanelSpTxtParent)
        else
            go = CS.UnityEngine.Object.Instantiate(PanelObj.TxtNor, PanelObj.PanelNorTxtParent)
        end
        
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.GameObject:SetActiveEx(true)
        
        if list[i].IsRare then
            tmpObj.TxtName.text = list[i].Name
            for index = 1, ProbMax do
                local txtProbability = tmpObj[string.format("TxtProbability%d", index)]
                if list[i].ProbShow[index] then
                    txtProbability.text = list[i].ProbShow[index]
                    txtProbability.gameObject:SetActiveEx(true)
                else
                    txtProbability.gameObject:SetActiveEx(false)
                end
            end
        else
            tmpObj.TxtName.text = list[i].Name
            tmpObj.TxtProbability.text = list[i].ProbShow[1]
        end
        
    end
    XScheduleManager.ScheduleOnce(function()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(PanelObj.PanelCardParent);
    end, 0)
end

function XUiDrawActivityLog:InitBtnTab()
    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self.TabGroup[i] = self[string.format("BtnTab%d", i)]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    self.PanelTabTc:SelectIndex(self.SelectIndex)
end

function XUiDrawActivityLog:OnBtnTanchuangClose()
    self:Close()
end

function XUiDrawActivityLog:OnSelectedTog(index)
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