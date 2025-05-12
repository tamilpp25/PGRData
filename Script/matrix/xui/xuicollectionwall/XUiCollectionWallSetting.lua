local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCollection = require("XUi/XUiMedal/XUiGridCollection")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiCollectionWallSetting = XLuaUiManager.Register(XLuaUi, "UiCollectionWallSetting")

local XUiGridCollectionWall = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridCollectionWall")

function XUiCollectionWallSetting:OnStart()
    -- 新旧设置缓存，用来检查是否作出了更改
    self.OldShowSetting = {}
    self.CurShowSetting = {}

    self:InitComponent()
    self:AddListener()
    self:SetupDynamicTable()
end

function XUiCollectionWallSetting:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(
            self,
            self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin
    )

    self.PanelNoneTemplate.gameObject:SetActiveEx(false)
    self.GridCollectionWall.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiCollectionWallSetting:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridCollectionWall, self, XCollectionWallConfigs.EnumWallGridOpenType.Setting)
    self.DynamicTable:SetDelegate(self)
end

function XUiCollectionWallSetting:SetupDynamicTable()
    self.PageDatas = XDataCenter.CollectionWallManager.GetNormalWallEntityList()
    --self.PageDatas = XDataCenter.CollectionWallManager.GetWallEntityList()

    for _, wallData in ipairs(self.PageDatas) do
        self.OldShowSetting[wallData:GetId()] = wallData:GetIsShow()
        self.CurShowSetting[wallData:GetId()] = wallData:GetIsShow()
    end

    self.PanelNoneTemplate.gameObject:SetActiveEx(#self.PageDatas <= 0)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(#self.PageDatas)
end

function XUiCollectionWallSetting:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index])
    end
end

---
--- 更改'wallDataId'的墙的展示设置缓存为'isShow'
---@param wallDataId number
---@param isShow boolean
function XUiCollectionWallSetting:ChangeCurShowSetting(wallDataId, isShow)
    self.CurShowSetting[wallDataId] = isShow
end

---
--- 检查是否有更改需要保存
function XUiCollectionWallSetting:CheckSave()
    local needSave = false

    for wallDataId, isShow in pairs(self.OldShowSetting) do
        if self.CurShowSetting[wallDataId] ~= isShow then
            needSave = true
            break
        end
    end

    return needSave
end

function XUiCollectionWallSetting:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "CollectionWall")
    self.BtnSave.CallBack = function()
        self:OnBtnSaveClick()
    end
    self.BtnPreview.CallBack = function()
        self:OnBtnPreviewClick()
    end
end

---
--- 保存收藏品墙展示设置
--- 在发送协议后更新收藏品墙数据实体(XCollectionWall)IsShow属性
--- 然后在回调中更新设置缓存
function XUiCollectionWallSetting:OnBtnSaveClick()
    if #self.PageDatas <= 0 then
        -- 没有对外展示的墙
        XUiManager.TipMsg(CS.XTextManager.GetText("CollectionWallNoneShow"))
        return
    end

    -- 构造发送请求需要的数据
    local showInfoList = {}
    for id, isShow in pairs(self.CurShowSetting) do
        local showInfo = {}
        showInfo.Id = id
        showInfo.IsShow = isShow
        table.insert(showInfoList, showInfo)
    end

    XDataCenter.CollectionWallManager.RequestEditCollectionWallIsShow(showInfoList, function()
        -- 保存后更新新旧设置缓存
        for _, wallData in ipairs(self.PageDatas) do
            self.OldShowSetting[wallData:GetId()] = wallData:GetIsShow()
            self.CurShowSetting[wallData:GetId()] = wallData:GetIsShow()
        end
        XUiManager.TipText("SetAppearanceSuccess")
    end)
end

---
--- 打开收藏品墙的展示界面，showWallList为需要展示的收藏品墙的数据实体数组
function XUiCollectionWallSetting:OnBtnPreviewClick()
    local showWallList = {}

    for id, isShow in pairs(self.CurShowSetting) do
        if isShow then
            table.insert(showWallList, XDataCenter.CollectionWallManager.GetWallEntityData(id))
        end
    end

    if next(showWallList) == nil then
        -- 没有对外展示的墙
        XUiManager.TipMsg(CS.XTextManager.GetText("CollectionWallNoneShow"))
    else
        XLuaUiManager.Open("UiCollectionWallView", showWallList, XDataCenter.MedalManager.InType.Normal)
    end
end

function XUiCollectionWallSetting:OnBtnBackClick()
    if self:CheckSave() then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SaveShowSetting"),
                XUiManager.DialogType.Normal,
                function()
                    self:Close()
                end,
                function()
                    self:OnBtnSaveClick()
                    self:Close()
                end)
        return
    end
    self:Close()
end

function XUiCollectionWallSetting:OnBtnMainUiClick()
    if self:CheckSave() then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SaveShowSetting"),
                XUiManager.DialogType.Normal,
                function()
                    XLuaUiManager.RunMain()
                end,
                function()
                    self:OnBtnSaveClick()
                    XLuaUiManager.RunMain()
                    XDataCenter.CollectionWallManager.ClearLocalCaptureCache()
                end)
        return
    end
    XLuaUiManager.RunMain()
    XDataCenter.CollectionWallManager.ClearLocalCaptureCache()
end