local XDrawTabBtnEntity = require("XEntity/XDrawMianButton/XDrawTabBtnEntity")
local XNormalDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XNormalDrawGroupBtnEntity")
local XLottoDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XLottoDrawGroupBtnEntity")

local XUiNewDrawMain = XLuaUiManager.Register(XLuaUi, "UiNewDrawMain")
local XUiNewGridDrawBanner = require("XUi/XUiDraw/XUiNewGridDrawBanner")
local ServerDataReadyMaxCount = 2--增加不同系统类型抽卡时记得酌情增加
function XUiNewDrawMain:OnStart(ruleType, groupId)
    self.RuleType = ruleType
    self.DefaultGroupId = groupId
    
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)
    
    self.MainBtnList = {}   -- 保存一级标签按钮物体，重复使用，在CreateMainBtn函数中，按钮不足时会生成按钮
    self.SubBtnList = {}    -- 保存二级标签按钮物体，重复使用，在CreateSubBtn函数中，按钮不足时会生成按钮

    self.CurBanner = {}
    
    self:SetButtonCallBack()
    self.IsFirstIn = true
    self.BtnIndex = 0
end

function XUiNewDrawMain:OnDestroy()
    self:MarkAllNewTag()
end

function XUiNewDrawMain:OnEnable()
    self:InitDrawCardsData()
end

function XUiNewDrawMain:SetButtonCallBack()
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
end

function XUiNewDrawMain:OnBtnBackClick()
    self:Close()
end

function XUiNewDrawMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNewDrawMain:InitDrawCardsData()
    self.readyCount = 0
    self.NormalGroupInfoList = {}
    self.LottoGroupInfoList = {}
    
    XDataCenter.DrawManager.GetDrawGroupList(function()--普通抽卡
            self.NormalGroupInfoList = XDataCenter.DrawManager.GetDrawGroupInfos()
            self:CheckServerDataReady()
        end)

    XDataCenter.LottoManager.GetLottoRewardInfoRequest(function()--皮肤抽卡
            self.LottoGroupInfoList = XDataCenter.LottoManager.GetLottoGroupDataList()
            self:CheckServerDataReady()
        end)
end

function XUiNewDrawMain:CheckServerDataReady()--增加不同系统类型抽卡时记得检查“ServerDataReadyMaxCount”是否相应的增加
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

    self.AllDataList = {}   -- 保存所有标签类,包括一级、二级标签类
    self.AllBtnList = {}    -- 保存所有标签按钮物体，包括一级、二级标签按钮物体

    self.SkipIndexDic = {}  -- DrawGroupId对应ButtonGroup的索引

    self:CreateDrawTabData(self.NormalGroupInfoList, XNormalDrawGroupBtnEntity) --普通抽卡
    self:CreateDrawTabData(self.LottoGroupInfoList, XLottoDrawGroupBtnEntity)   --皮肤抽卡
    self:SortDrawTabData()
    self:InitButtonGroup()
end

---
--- 初始化一级标签类，并保存其子标签类
function XUiNewDrawMain:CreateDrawTabData(groupInfoList,class)----增加不同系统类型抽卡时页签生成需要添加对应的实体与初始化逻辑
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
    table.sort(self.DrawTabList,function (a,b)
            return a:GetPriority() < b:GetPriority()
        end)
end

---
--- 初始化按钮组，选择默认标签
function XUiNewDrawMain:InitButtonGroup()
    self:BtnInit(self.MainBtnList)
    self:BtnInit(self.SubBtnList)
    
    for _,drawTab in pairs(self.DrawTabList or {}) do
        local subgroupIndex = self:CreateMainBtn(drawTab)
        for _,drawGroupInfo in pairs(drawTab:GetDrawGroupList() or {}) do
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
        if not curBtnIndex and self.IsFirstIn then
            curBtnIndex = 1
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

    self.IsFirstIn = false
    self.PanelNoticeTitleBtnGroup:Init(self.AllBtnList, function(index) self:OnSelectedTog(index) end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(self.AllBtnList[curBtnIndex] and curBtnIndex or 1)
end

function XUiNewDrawMain:BtnInit(BtnList)
    for _,btn in pairs(BtnList or {}) do
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
        if self.AllDataList[index]:DoSelect(self) then
            self.CurSelectId = index
            self.AssetActivityPanel:Refresh(self.AllDataList[index]:GetUseItemIdList())
        end
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
        uiButton:SetNameByGroup(0, IsUnLock and (string.format("0%d",data:GetTxtName1())) or "")
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
function XUiNewDrawMain:CreateSubBtn(subGroupIndex,data)
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
    local prefab = self.PanelBanner:LoadPrefab(data:GetBanner())
    self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
    self.CurBanner.GameObject.name = data:GetId()
end

function XUiNewDrawMain:GetRelationGroupData(id)
    local groupRelationDic = XDrawConfigs.GetDrawGroupRelationDic()
    local relationGroupId = groupRelationDic[id]
    if relationGroupId then
        for _,data in pairs(self.AllDataList or {}) do
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