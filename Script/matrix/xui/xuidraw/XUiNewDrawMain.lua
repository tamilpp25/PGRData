local XDrawTabBtnEntity = require("XEntity/XDrawMianButton/XDrawTabBtnEntity")
local XNormalDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XNormalDrawGroupBtnEntity")
local XLottoDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XLottoDrawGroupBtnEntity")
local XUiDrawControl = require("XUi/XUiDraw/XUiDrawControl")
local XUiDrawScene = require("XUi/XUiDraw/XUiDrawScene")

local XUiNewDrawMain = XLuaUiManager.Register(XLuaUi, "UiNewDrawMain")
local XUiNewGridDrawBanner = require("XUi/XUiDraw/XUiNewGridDrawBanner")
local ServerDataReadyMaxCount = 2 --增加不同系统类型抽卡时记得酌情增加
local DEFAULT_UP_IMG = CS.XGame.ClientConfig:GetString("DrawDefaultUpImg")
local GUIDE_SHOW_GROUP = CS.XGame.ClientConfig:GetInt("GuideShowGroup")
function XUiNewDrawMain:OnStart(ruleType, groupId)
    self.RuleType = ruleType
    self.DefaultGroupId = groupId
    if XLuaUiManager.IsUiShow("UiGuide") then
        self.DefaultGroupId = GUIDE_SHOW_GROUP
    end
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)

    self.MainBtnList = {} -- 保存一级标签按钮物体，重复使用，在CreateMainBtn函数中，按钮不足时会生成按钮
    self.SubBtnList = {} -- 保存二级标签按钮物体，重复使用，在CreateSubBtn函数中，按钮不足时会生成按钮
    self.DrawScene = XUiDrawScene.New(self)
    self.CurBanner = nil
    self.TextWelfare = self.LabelWelfare:FindTransform("TextWelfare"):GetComponent("Text")
    self:SetButtonCallBack()
    self.BtnIndex = 0
end

function XUiNewDrawMain:OnDestroy()
    self:MarkAllNewTag()
end

function XUiNewDrawMain:OnEnable()
    self:InitDrawCardsData()
    if self.CurBanner then
        self.CurBanner:Refresh()
    end
end

function XUiNewDrawMain:SetButtonCallBack()
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnOptionalDraw.CallBack = function()
        self:OnBtnOptionDrawClick()
    end
    self.BtnDrawPurchaseLB.CallBack = function()
        self:OnBtnLBClick()
    end
end

function XUiNewDrawMain:OnBtnBackClick()
    self:Close()
end

function XUiNewDrawMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNewDrawMain:OnBtnOptionDrawClick()
local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    XLuaUiManager.Open("UiDrawOptional", self,
        function(drawId)
                    self:OnSelectUp(drawId)
                self:RefreshScene()
        end,
        function()
            self:Close()
        end, groupInfo.UseDrawId)
end

function XUiNewDrawMain:OnBtnLBClick()
    self:OpenChildUi("UiDrawPurchaseLB", self)
end

function XUiNewDrawMain:OnSelectUp(drawId)
    local drawInfo = XDataCenter.DrawManager.GetDrawInfo(drawId)
    self.DrawInfo = drawInfo
    self:UpdatePurchase()
    self.DrawControl:Update(drawInfo)
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawInfo.Id)
    if not combination then
        self.BtnOptionalDraw.gameObject:SetActiveEx(false)
        return
    end
    self.CurDrawType = combination.Type
    self.BtnOptionalDraw.gameObject:SetActiveEx(true)
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    if drawAimProbability[drawId] then
        self.TxtProbability.text = drawAimProbability[drawId].UpProbability or ""
    end
    if not combination.GoodsId[1] then
        self.ImgQuality.gameObject:SetActiveEx(false)
        self.RImgRole:SetRawImage(DEFAULT_UP_IMG)
        self.AllDataList[self.CurSelectId]:DoSelect(self)
        return
    end
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(combination.GoodsId[1])

    self.RImgRole:SetRawImage(self.GoodsShowParams.Icon)
    if self.GoodsShowParams.QualityIcon then
        self:SetUiSprite(self.ImgQuality, self.GoodsShowParams.QualityIcon)
    end
    self.ImgQuality.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.GoodsShowParams.QualityIcon))
    self.AllDataList[self.CurSelectId]:DoSelect(self)
end

function XUiNewDrawMain:Refresh()
    self:OnSelectUp(self.DrawInfo.Id)
    self:RefreshScene()
    if self.LabelWelfare then
        local isBottomHintShow = self.DrawInfo.IsTriggerSpecified and self.DrawInfo.IsTriggerSpecified or false
        local isNewHandShow = self.DrawInfo.MaxBottomTimes == self.AllDataList[self.CurSelectId]:GetNewHandBottomCount()
        if isBottomHintShow then
            self.TextWelfare.text = CS.XTextManager.GetText("NewDrawCalibration")
        end
        if isNewHandShow then
            self.TextWelfare.text = CS.XTextManager.GetText("NewDrawNewHand")
        end
        self.LabelWelfare.gameObject:SetActiveEx(isNewHandShow or isBottomHintShow)
    end
end

function XUiNewDrawMain:InitDrawCardsData()
    self.readyCount = 0
    self.NormalGroupInfoList = {}

    XDataCenter.DrawManager.GetDrawGroupList(function() --普通抽卡
        self.NormalGroupInfoList = XDataCenter.DrawManager.GetDrawGroupInfos()
        self:CheckServerDataReady()
    end)

    XDataCenter.LottoManager.GetLottoRewardInfoRequest(function() --皮肤抽卡
        self.LottoGroupInfoList = XDataCenter.LottoManager.GetLottoGroupDataList()
        self:CheckServerDataReady()
    end)
end

function XUiNewDrawMain:CheckServerDataReady() --增加不同系统类型抽卡时记得检查“ServerDataReadyMaxCount”是否相应的增加
    self.readyCount = self.readyCount + 1
    if self.readyCount == ServerDataReadyMaxCount then
        self:InitDrawTabs()
    end
end

function XUiNewDrawMain:InitDrawTabs()
    self.BtnIndex = 1
    self.MainBtnCount = 1
    self.SubBtnCount = 1

    -- 保存一级标签（XDrawTabBtnEntity类）的字典与数组
    self.DrawTabDic = {}
    self.DrawTabList = {}

    self.AllDataList = {} -- 保存所有标签类,包括一级、二级标签类
    self.AllBtnList = {} -- 保存所有标签按钮物体，包括一级、二级标签按钮物体

    self.SkipIndexDic = {} -- DrawGroupId对应ButtonGroup的索引

    self:CreateDrawTabData(self.NormalGroupInfoList, XNormalDrawGroupBtnEntity) --普通抽卡
    self:CreateDrawTabData(self.LottoGroupInfoList, XLottoDrawGroupBtnEntity) --皮肤抽卡
    self:SortDrawTabData()
    self:InitButtonGroup()
end

---
--- 初始化一级标签类，并保存其子标签类
function XUiNewDrawMain:CreateDrawTabData(groupInfoList, class) ----增加不同系统类型抽卡时页签生成需要添加对应的实体与初始化逻辑
    for _, drawGroupInfo in pairs(groupInfoList or {}) do

        local groupEntity = class.New() -- 生成组（二级标签）按钮用实体
        groupEntity:UpdateData(drawGroupInfo)

        if not self.DrawTabDic[groupEntity:GetTag()] then
            self.DrawTabDic[groupEntity:GetTag()] = XDrawTabBtnEntity.New(groupEntity:GetTag()) -- 生成类（一级标签）按钮用实体
            table.insert(self.DrawTabList, self.DrawTabDic[groupEntity:GetTag()])
        end

        self.DrawTabDic[groupEntity:GetTag()]:InsertDrawGroupList(groupEntity)
    end
end

function XUiNewDrawMain:SortDrawTabData()
    table.sort(self.DrawTabList, function(a, b)
        return a:GetPriority() < b:GetPriority()
    end)
end

function XUiNewDrawMain:UpdatePurchase()
    if self.DrawInfo then
        if self.DrawInfo.PurchaseId and next(self.DrawInfo.PurchaseId) then
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(true)
            if self.DrawInfo.PurchaseUiType and self.DrawInfo.PurchaseUiType ~= 0 then
                local uiType = self.DrawInfo.PurchaseUiType
                XDataCenter.PurchaseManager.GetPurchaseListRequest(uiType)
            end
        else
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(false)
        end
    end
end

---
--- 初始化按钮组，选择默认标签
function XUiNewDrawMain:InitButtonGroup()
    self:BtnInit(self.MainBtnList)
    self:BtnInit(self.SubBtnList)

    for _, drawTab in pairs(self.DrawTabList or {}) do
        local subgroupIndex = self:CreateMainBtn(drawTab)
        for _, drawGroupInfo in pairs(drawTab:GetDrawGroupList() or {}) do
            self:CreateSubBtn(subgroupIndex, drawGroupInfo)
        end
    end

    local curBtnIndex = 0
    local tmpGroupId = 0

    if self.DefaultGroupId then
        tmpGroupId = self.DefaultGroupId
        curBtnIndex = self:GetBtnIndexByGroupId(self.RuleType, tmpGroupId)
        self.DefaultGroupId = nil
    else
        tmpGroupId = XDataCenter.DrawManager.GetLostSelectDrawGroupId()
        local tmptype = XDataCenter.DrawManager.GetLostSelectDrawType()
        curBtnIndex = self:GetBtnIndexByGroupId(tmptype, tmpGroupId)
        if not curBtnIndex then
            local groupId = XDataCenter.DrawManager.GetGroupIdWithMaxOrder()
            curBtnIndex = self:GetBtnIndexByGroupId(self.RuleType, groupId)
        end
    end

    if curBtnIndex then
        local tagEntity = self.AllDataList[curBtnIndex]
        if tagEntity and not tagEntity:IsMainButton() then
            -- 如果tagEntity为二级标签,则获取它所属的一级标签,然后判断是否可以打开
            local mainTagEntity = self.DrawTabDic[tagEntity:GetTag()]
            local isOpen = mainTagEntity:JudgeCanOpen(true)
            if not isOpen then
                curBtnIndex = 1
            end
        end
    else
        XUiManager.TipText("NewDrawSkipNotInTime")
        curBtnIndex = 1
    end

    self.PanelNoticeTitleBtnGroup:Init(self.AllBtnList, function(index) self:OnSelectedTog(index) end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(self.AllBtnList[curBtnIndex] and curBtnIndex or 1)
end

function XUiNewDrawMain:BtnInit(BtnList)
    for _, btn in pairs(BtnList or {}) do
        btn.gameObject:SetActiveEx(false)
        btn:SetButtonState(CS.UiButtonState.Normal)
        btn.TempState = CS.UiButtonState.Normal
        btn.IsFold = false --初始化时需要把按钮的状态已打开设置为false
    end
end

function XUiNewDrawMain:GetBtnIndexByGroupId(ruleType, groupId)
    local curBtnIndex = self.SkipIndexDic and
            self.SkipIndexDic[ruleType] and
            self.SkipIndexDic[ruleType][groupId]
    return curBtnIndex
end

---
--- 一级标签的按钮状态为Disable时传入的index为它自己的index，否则为它的第一个子标签的index
---
--- 只有一级标签类才会判断是否能打开卡池
function XUiNewDrawMain:OnSelectedTog(index)
    if self.AllDataList[index] then
        local IsTypeTab = self.AllDataList[index]:GetRuleType() == XDrawConfigs.RuleType.Tab
        self.RuleType = not IsTypeTab and
                self.AllDataList[index]:GetRuleType() or self.RuleType
        if not IsTypeTab then
            XDataCenter.DrawManager.SetLostSelectDrawGroupId(self.AllDataList[index]:GetId())
            XDataCenter.DrawManager.SetLostSelectDrawType(self.RuleType)
        end
        if self.AllDataList[index]:IsMainButton() then
            if not self.AllDataList[index]:JudgeCanOpen(true) then
                return
            end
            self.GroupId = self.AllDataList[index].DrawGroupList[1].Id
        else
            self.GroupId = self.AllDataList[index]:GetId()
        end
        self.CurSelectId = index
        XDataCenter.DrawManager.GetDrawInfoList(self.GroupId, function()
            local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.GroupId)
            self.DrawInfo = drawInfo
            self.AllDataList[index].MaxBottomTimes = self.DrawInfo.MaxBottomTimes
            self.AllDataList[index].BottomTimes = self.DrawInfo.BottomTimes
            self.AllDataList[index]:DoSelect(self)
            self:UpdatePurchase()
            if not self.DrawControl then
                self.DrawControl = XUiDrawControl.New(self, drawInfo, function()
                end, self)
            else
                self.DrawControl:Update(drawInfo)
            end
            self:Refresh()
            self:CheckAutoOpen()
            local data = self.AllDataList[index]
            self.AssetActivityPanel:Refresh(data:GetUseItemIdList())
            XDataCenter.ItemManager.AddCountUpdateListener(self.AllDataList[index]:GetUseItemIdList(),
                function()
                    self.AssetActivityPanel:Refresh(self.AllDataList[index]:GetUseItemIdList())
                end, self.AssetActivityPanel)
        end)
    end
end

---
--- 初始化一级标签按钮物体
function XUiNewDrawMain:CreateMainBtn(data)
    local uiButton = self.MainBtnList[self.MainBtnCount]
    if not uiButton then
        local obj = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
        uiButton = obj:GetComponent("XUiButton")
        self.MainBtnList[self.MainBtnCount] = uiButton
    end
    if uiButton then
        uiButton.gameObject:SetActiveEx(true)
        uiButton.transform:SetParent(self.transform, false)
        uiButton.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        local IsUnLock = data:JudgeCanOpen(false)
        uiButton:SetDisable(not IsUnLock)
        uiButton:SetNameByGroup(0, IsUnLock and (string.format("0%d", data:GetTxtName1())) or "")
        uiButton:SetNameByGroup(1, data:GetTxtName2())
        uiButton:SetNameByGroup(2, data:GetTxtName3())
        uiButton:SetRawImage(data:GetTabBg())
        uiButton:ShowTag(data:IsShowTag())

        table.insert(self.AllBtnList, uiButton)
        table.insert(self.AllDataList, data)
    end
    local subGroupIndex = self.BtnIndex
    self.BtnIndex = self.BtnIndex + 1
    self.MainBtnCount = self.MainBtnCount + 1
    return subGroupIndex
end

---
--- 初始化二级标签按钮物体
function XUiNewDrawMain:CreateSubBtn(subGroupIndex, data)
    local uiButton = self.SubBtnList[self.SubBtnCount]
    if not uiButton then
        local obj = CS.UnityEngine.Object.Instantiate(self.BtnChild)
        uiButton = obj:GetComponent("XUiButton")
        self.SubBtnList[self.SubBtnCount] = uiButton
    end
    if uiButton then
        uiButton.gameObject:SetActiveEx(true)
        uiButton.transform:SetParent(self.transform, false)
        uiButton.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        local uiObject = uiButton.transform:GetComponent("UiObject")
        uiButton:SetName(data:GetName())
        uiButton:SetRawImage(data:GetGroupBtnBg())
        uiButton.SubGroupIndex = subGroupIndex
        uiObject:GetObject("A").gameObject:SetActiveEx(data:GetRareRank() == XDrawConfigs.RareRank.A)
        uiObject:GetObject("S").gameObject:SetActiveEx(data:GetRareRank() == XDrawConfigs.RareRank.S)

        self.SkipIndexDic[data:GetRuleType()] = self.SkipIndexDic[data:GetRuleType()] or {}
        self.SkipIndexDic[data:GetRuleType()][data:GetId()] = self.BtnIndex

        uiButton:ShowTag(data:IsShowTag())

        table.insert(self.AllBtnList, uiButton)
        table.insert(self.AllDataList, data)
    end
    self.BtnIndex = self.BtnIndex + 1
    self.SubBtnCount = self.SubBtnCount + 1
end

function XUiNewDrawMain:CreateBanner(data)
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(data:GetId())
    if drawInfo.Banner then
        local prefab = self.PanelBanner:LoadPrefab(drawInfo.Banner)
        self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
        self.CurBanner.GameObject.name = data:GetId()
    else
        local prefab = self.PanelBanner:LoadPrefab(data:GetBanner())
        self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
        self.CurBanner.GameObject.name = data:GetId()
    end

    if drawInfo.Resources then
        self.CurBanner:SetImage(drawInfo.Resources)
    end
end

function XUiNewDrawMain:GetRelationGroupData(id)
    local groupRelationDic = XDrawConfigs.GetDrawGroupRelationDic()
    local relationGroupId = groupRelationDic[id]
    if relationGroupId then
        for _, data in pairs(self.AllDataList or {}) do
            if data:GetId() == relationGroupId then
                return data
            end
        end
    end
    return
end

function XUiNewDrawMain:MarkCurNewTag()
    if self.CurSelectId then
        self:DoMark(self.CurSelectId)
    else
        XLog.Error("XUiNewDrawMain:MarkCurNewTag函数错误，self.CurSelectId为nil")
    end
end

function XUiNewDrawMain:MarkAllNewTag()
    for index = 1, self.BtnIndex do
        self:DoMark(index)
    end
end

function XUiNewDrawMain:DoMark(index)
    if self.AllDataList[index] and self.AllBtnList[index] then
        if self.AllBtnList[index].SubGroupIndex > 0 and self.AllDataList[index]:GetBannerBeginTime() > 0 then
            XDataCenter.DrawManager.MarkNewTag(self.AllDataList[index]:GetBannerBeginTime(),
                self.AllDataList[index]:GetRuleType(),
                self.AllDataList[index]:GetId())

            self.AllBtnList[index]:ShowTag(false)
        end
    end
end

function XUiNewDrawMain:CheckAutoOpen()
    if self.CurDrawType ~= XDrawConfigs.CombinationsTypes.Aim then
        return
    end
    local IsHaveActivty = false
    local activtyTime = 0
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    local drawInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(self.GroupId)
    for _, drawInfo in pairs(drawInfoList) do
        if drawInfo.StartTime > 0 then
            IsHaveActivty = true
            if drawInfo.StartTime > activtyTime then
                activtyTime = drawInfo.StartTime
            end
        end
    end

    local IsCanActivtyOpen = IsHaveActivty and XDataCenter.DrawManager.IsCanAutoOpenAimGroupSelect(activtyTime, self.GroupId)
    if IsCanActivtyOpen or (groupInfo.MaxSwitchDrawIdCount > 0 and groupInfo.UseDrawId == 0) and (not XLuaUiManager.IsUiLoad("UiDrawOptional")) then
        self:OnBtnOptionDrawClick()
    end
end

function XUiNewDrawMain:RefreshScene()
    if self.LastSceneId == self.DrawInfo.Id then
        return
    end
    self.LastSceneId = self.DrawInfo.Id
    local drawSceneCfg = XDrawConfigs.GetDrawSceneCfg(self.DrawInfo.Id)
    if not drawSceneCfg then
        return
    end
    self.DrawScene:RefreshScene(drawSceneCfg)
end
