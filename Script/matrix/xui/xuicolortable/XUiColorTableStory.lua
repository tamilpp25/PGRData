local UiGridColorTableStory = require("XUi/XUiColorTable/Grid/XUiGridColorTableStory")

-- 调色战争遭遇图鉴
local XUiColorTableStory = XLuaUiManager.Register(XLuaUi, "UiColorTableStory")
local SelectTagIndex = 1

function XUiColorTableStory:OnAwake()
    self.TagBtnList = nil
    self.TagInfoList = nil 

    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTimes()
    self:InitAssetPanel()
end

function XUiColorTableStory:OnEnable()
    self.Super.OnEnable(self)
    self.TabBtnContent:SelectIndex(SelectTagIndex)
    self:UpdateTagBtnList()
    self:UpdateAssetPanel()
end

function XUiColorTableStory:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableStory:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)

    -- 子类型为页签
    self.TagBtnList = {}
	self.TagInfoList = self:GetHandBookSubTypeList()
    for index, info in pairs(self.TagInfoList) do
    	local go = self.BtnTabShortNew
    	if index > 1 then
    		go = CS.UnityEngine.Object.Instantiate(self.BtnTabShortNew, self.BtnTabShortNew.transform.parent)
    	end
    	local btn = go:GetComponent("XUiButton")
    	btn:SetName(info.SubTypeName)
    	table.insert(self.TagBtnList, btn)
    end
    self.TabBtnContent:Init(self.TagBtnList, function(index) self:SelectTag(index) end)
end

function XUiColorTableStory:SelectTag(index)
	SelectTagIndex = index
	self:RefreshDynamicTable()
end

function XUiColorTableStory:OnBtnCloseClick()
    SelectTagIndex = 1
    self:Close()
end

function XUiColorTableStory:OnBtnMainUiClick()
    SelectTagIndex = 1
    XLuaUiManager.RunMain()
end

function XUiColorTableStory:InitDynamicTable()
    self.GridStoryItem.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(UiGridColorTableStory)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableStory:RefreshDynamicTable()
    local subType = self.TagInfoList[SelectTagIndex].SubType
    self.DataList = self:GetHandBookList(subType)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)

    -- 解锁进度
    local unLockCnt = 0
    for _, handBookConfig in ipairs(self.DataList) do
        local isUnlock = XDataCenter.ColorTableManager.IsHandbookUnlock(handBookConfig.Id)
        if isUnlock then 
            unLockCnt = unLockCnt + 1
        end
    end
    self.TxtHaveCollectNum.text = unLockCnt
    self.TxtMaxCollectNum.text = #self.DataList
end

function XUiColorTableStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local config = self.DataList[index]
        grid:Refresh(self, config)
    end
end

function XUiColorTableStory:UpdateTagBtnList()
    for i, _ in ipairs(self.TagInfoList) do
        self:UpdateTagBtnRed(i)
    end
end

function XUiColorTableStory:UpdateTagBtnRed(index)
    local info = self.TagInfoList[index]
    local isRed = false
    local list = self:GetHandBookList(info.SubType)
    for _, config in ipairs(list) do
        if config.Type == XColorTableConfigs.HandBookType.Drama then
            local isUnlock = XDataCenter.ColorTableManager.IsHandbookUnlock(config.Id)
            local isPlayed = XDataCenter.ColorTableManager.IsDramaPlayed(config.DramaId)
            if isUnlock and not isPlayed then
                isRed = true
                break
            end
        end
    end

    self.TagBtnList[index]:ShowReddot(isRed)
end

function XUiColorTableStory:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end


-- 以subType为页签，获取图鉴页签列表
function XUiColorTableStory:GetHandBookSubTypeList()
    local subTypeDic = {}
    local subTypeList = {}

    -- 图鉴表
    local handBookConfig = XColorTableConfigs.GetColorTableHandbook()
    for _, config in ipairs(handBookConfig) do
        if subTypeDic[config.SubType] == nil then
            table.insert(subTypeList, {SubType = config.SubType, SubTypeName = config.SubTypeName})
            subTypeDic[config.SubType] = true
        end
    end

    -- 关卡结束剧情表
    local stageEndStoryConfig = XColorTableConfigs.GetColorTableStageEndStory()
    for _, config in ipairs(stageEndStoryConfig) do
        if subTypeDic[config.HandBookSubType] == nil then
            table.insert(subTypeList, {SubType = config.HandBookSubType, SubTypeName = config.HandBookSubTypeName})
            subTypeDic[config.HandBookSubType] = true
        end
    end

    table.sort(subTypeList, function(a, b)
        return a.SubType < b.SubType
    end)
    return subTypeList
end

-- 以subType为页签，获取页签对应的图鉴列表
function XUiColorTableStory:GetHandBookList(subType)
    local cfgList = {}

    -- 图鉴表
    local handBookConfig = XColorTableConfigs.GetColorTableHandbook()
    for _, config in ipairs(handBookConfig) do
        if config.SubType == subType then
            table.insert(cfgList, config)
        end
    end

    -- 关卡结束剧情表
    local stageEndStoryConfig = XColorTableConfigs.GetColorTableStageEndStory()
    for _, config in ipairs(stageEndStoryConfig) do
        if config.HandBookSubType == subType then
            table.insert(cfgList, config)
        end
    end
    return cfgList
end

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiColorTableStory:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiColorTableStory:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------