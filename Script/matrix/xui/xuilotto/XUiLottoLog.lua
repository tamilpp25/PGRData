local XUiLottoLog = XLuaUiManager.Register(XLuaUi, "UiLottoLog")
local BtnMaxCount = 4
local TypeText = {}
local IsInit = {}
local AnimeNames = {}
local InitFunctionList = {}
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString
local DrawLogLimit = CS.XGame.ClientConfig:GetInt("DrawLogLimit")
function XUiLottoLog:OnStart(data, selectIndex)
    self.LottoGroupData = data
    self.SelectIndex = selectIndex or XDataCenter.LottoManager.GetRuleTagIndex()
    self.RewardCore = {}
    self.RewardFirst = {}
    self.RewardSecond = {}
    self.RewardThird = {}
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    InitFunctionList = {
        function()
            self:InitRewardDetails()
        end,
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

function XUiLottoLog:SetTypeText()
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
end

function XUiLottoLog:InitDrawLogListPanel()
    local drawData = self.LottoGroupData:GetDrawData()
    local lottoLogList = drawData:GetLottoRecordList()
    local name
    local quality
    local fromName
    local time

    local PanelObj = {}
    PanelObj.Transform = self.Panel4.transform
    XTool.InitUiObject(PanelObj)

    PanelObj.GridLogHigh.gameObject:SetActiveEx(false)
    PanelObj.GridLogMid.gameObject:SetActiveEx(false)
    PanelObj.GridLogLow.gameObject:SetActiveEx(false)
    PanelObj.TxtLogCount.text = CS.XTextManager.GetText("DrawLogCpunt", DrawLogLimit)
    
    local bottomText = CS.XTextManager.GetText("NewDrawMainBottomText")
    PanelObj.TxtEnsureCount.text = string.format("%s %s/%s", bottomText, drawData:GetCurRewardCount(), drawData:GetMaxRewardCount())
    
    for _, v in pairs(lottoLogList) do
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
            time = TimestampToGameDateTimeString(v.LottoTime)
            self:SetLogData(PanelObj, fromName, v.RewardGoods.ConvertFrom, name, time, quality)
        else
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = Goods.Quality
            quality = quality or 1
            name = Goods.Name
            if Goods.TradeName then
                name = string.format("%s.%s", name,Goods.TradeName)
            end
            time = TimestampToGameDateTimeString(v.LottoTime)
            self:SetLogData(PanelObj, name, v.RewardGoods.TemplateId, nil, time, quality)
        end
    end
end

function XUiLottoLog:SetLogData(obj, name, templateId, from, time, quality)
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

function XUiLottoLog:InitRewardDetails()
    self:UpdatePanelReward(self.Panel1:GetObject("PanelItem1"), self.RewardCore, XLottoConfigs.RareLevel.One)
    self:UpdatePanelReward(self.Panel1:GetObject("PanelItem2"), self.RewardFirst, XLottoConfigs.RareLevel.Two)
    self:UpdatePanelReward(self.Panel1:GetObject("PanelItem3"), self.RewardSecond, XLottoConfigs.RareLevel.Three)
    self:UpdatePanelReward(self.Panel1:GetObject("PanelItem4"), self.RewardThird, XLottoConfigs.RareLevel.Four)
end

function XUiLottoLog:UpdatePanelReward(panel, rewardDic, rareLevel)
    local drawData = self.LottoGroupData:GetDrawData()
    local rewardDataList = drawData:GetRewardDataList()
    local gridObj = self.Panel1:GetObject("GridItem")
    
    gridObj.gameObject:SetActiveEx(false)
    for _,rewardData in pairs(rewardDataList) do
        if rewardData:GetRareLevel() == rareLevel then
            local reward = rewardDic[rewardData:GetId()]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(gridObj, panel)
                obj.gameObject:SetActiveEx(true)
                reward = XUiGridCommon.New(self.Base, obj)
                rewardDic[rewardData:GetId()] = reward
            end
            if reward then
                local tmpData = {TemplateId = rewardData:GetTemplateId(), Count = rewardData:GetCount()}
                reward:Refresh(tmpData, nil, nil, nil, rewardData:GetIsGeted() and 0 or 1)
            end
        end
    end
end

function XUiLottoLog:InitBaseRulePanel()
    local baseRules = self.LottoGroupData:GetBaseRulesList()
    local baseRuleTitles = self.LottoGroupData:GetBaseRuleTitleList()
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel2)
end

function XUiLottoLog:SetRuleData(rules, ruleTitles, panel)
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
        tmpObj.TxtRuleTitle.text = ruleTitles[k]
        tmpObj.TxtRule.text = rules[k]
        tmpObj.GameObject:SetActiveEx(true)
    end
end

function XUiLottoLog:InitDrawPreview()
    local PanelObj = {}
    PanelObj.Transform = self.Panel3.transform
    XTool.InitUiObject(PanelObj)

    PanelObj.RewardSp.gameObject:SetActiveEx(false)
    PanelObj.RewardNor.gameObject:SetActiveEx(false)
    
    local drawData = self.LottoGroupData:GetDrawData()
    local rewardDataList = drawData:GetRewardDataList()
   
    if not rewardDataList then
        return
    end
    for i = 1, #rewardDataList do
        local obj
        if rewardDataList[i]:GetRareLevel() == XLottoConfigs.RareLevel.One then
            obj = CS.UnityEngine.Object.Instantiate(PanelObj.RewardSp, PanelObj.Content)
        else
            obj = CS.UnityEngine.Object.Instantiate(PanelObj.RewardNor, PanelObj.Content)
        end
        
        self:InitDrawProb(obj,rewardDataList[i])
        
    end
    XScheduleManager.ScheduleOnce(function()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(PanelObj.Content);
    end, 0)
end

function XUiLottoLog:InitDrawProb(obj, rewardData)
    local rewardObj = {}
    rewardObj.Transform = obj.transform
    rewardObj.GameObject = obj.gameObject
    XTool.InitUiObject(rewardObj)
    rewardObj.GameObject:SetActiveEx(true)
    
    local itemObj = rewardObj.RewardItem:GetObject("GridCostItem")
    local item = XUiGridCommon.New(self, itemObj)
    local tmpData = {TemplateId = rewardData:GetTemplateId(), Count = rewardData:GetCount()}
    item:Refresh(tmpData)
    
    rewardObj.RewardProb.gameObject:SetActiveEx(false)
    local probShowList = rewardData:GetProbShowList()
    for index = 1, #probShowList do
        local probObj = CS.UnityEngine.Object.Instantiate(rewardObj.RewardProb, rewardObj.PanelDropTitleContent)
        probObj.gameObject:SetActiveEx(true)
        local prob = probObj.transform:GetComponent("UiObject")
        prob:GetObject("TxtCount").text = probShowList[index]
    end
end

function XUiLottoLog:InitBtnTab()
    self.TabGroup = self.TabGroup or {}
    for i = 1, BtnMaxCount do
        if not self.TabGroup[i] then
            self.TabGroup[i] = self[string.format("BtnTab%d", i)]
        end
    end
    self.PanelTabTc:Init(self.TabGroup, function(tabIndex) self:OnSelectedTog(tabIndex) end)
    self.PanelTabTc:SelectIndex(self.SelectIndex)
end

function XUiLottoLog:OnBtnTanchuangClose()
    self:Close()
end

function XUiLottoLog:OnSelectedTog(index)
    for i = 1, BtnMaxCount do
        self[string.format("Panel%d", i)].gameObject:SetActiveEx(false)
    end

    self[string.format("Panel%d", index)].gameObject:SetActiveEx(true)
    if not IsInit[index] then
        InitFunctionList[index]()
        IsInit[index] = true
    end

    self:PlayAnimation(AnimeNames[index])
    XDataCenter.LottoManager.SetRuleTagIndex(index)
end