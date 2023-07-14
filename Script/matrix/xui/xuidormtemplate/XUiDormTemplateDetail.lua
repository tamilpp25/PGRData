local XUiDormTemplateDetail = XLuaUiManager.Register(XLuaUi, "UiDormTemplateDetail")
local XUiGridTemplateDetail = require("XUi/XUiDormTemplate/XUiGridTemplateDetail")
local XUiPanelTemlateSelectRoom = require("XUi/XUiDormTemplate/XUiPanelTemlateSelectRoom")
local XUiPanelRefitQuick = require("XUi/XUiDormTemplate/XUiPanelRefitQuick")

local SELECT_TYPE = {
    All         = 0, -- 全选
    Enough      = 1, -- 已经达成
    NotEnough   = 2 -- 未达成
}

function XUiDormTemplateDetail:OnAwake()
    self:AddListener()
end

function XUiDormTemplateDetail:OnStart(homeRoomData, enterSceneCb)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.DormCoin,
    XDataCenter.ItemManager.ItemId.FurnitureCoin,
    XDataCenter.ItemManager.ItemId.DormEnterIcon)
    self.SelectRoomPanel = XUiPanelTemlateSelectRoom.New(self.PanelSelectRoom, self, function(freshHomeRoomData)
        self:Refresh(freshHomeRoomData)
    end)
    self.RefitPanel = XUiPanelRefitQuick.New(self.PanelRefitQuick, self)
    self.EnterSceneCb = enterSceneCb
    self.PageDatas = {}
    self.SortType = SELECT_TYPE.All
    self:InitDynamicTable()
    self:Refresh(homeRoomData)
end

function XUiDormTemplateDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_BUYASSET, self.RefitPanel.UpdateTxtDrawingCount, self.RefitPanel)
    XEventManager.AddEventListener(XEventId.EVENT_FURNITURE_GET_FURNITURE, self.RefitPanel.OnGetFurniture, self.RefitPanel)
    self:Refresh()
end

function XUiDormTemplateDetail:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewClick)
    self:RegisterClickEvent(self.BtnTarget, self.OnBtnTargetClick)
    self:RegisterClickEvent(self.BtnPut, self.OnBtnPutClick)
    self.DrdSort.onValueChanged:AddListener(function()
        self.SortType = self.DrdSort.value
        self:RefreshSelectedPanel()
    end)
end

function XUiDormTemplateDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDormTemplateDetail:OnBtnBackClick()
    self:Close()
end

function XUiDormTemplateDetail:OnBtnPreviewClick()
    if self.EnterSceneCb then
        self.EnterSceneCb()
    end

    XDataCenter.DormManager.EnterTemplateDormitory(self.RoomId, self.RoomType)
end

-- 选择宿舍
function XUiDormTemplateDetail:OnBtnTargetClick()
    self:PlayAnimation("SelectRoomEnable")
    self.SelectRoomPanel:Open(self.HomeRoomData, self.CurDormId)
end

-- 打开快捷建造界面
function XUiDormTemplateDetail:OpenRefitQuick(furnitureData)
    self:PlayAnimation("RefitQuickEnable")
    self.RefitPanel:Open(furnitureData)
end

-- 一键摆放
function XUiDormTemplateDetail:OnBtnPutClick()
    local connectRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("DormTemplateOneKeyTip", connectRoom:GetRoomName())

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.DormManager.CopyTemplateDorm(self.ConnectId, self.RoomId, self.RoomType, function()
            XUiManager.TipSuccess(CS.XTextManager.GetText("DormTemplateOneKeySuccesss"))
            self:Refresh()
            if self.EnterSceneCb then
                local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
                local characterIds = roomData:GetCharacterIds()
                XDataCenter.DormManager.ResetPutCharacter(self.ConnectId, characterIds)
            end
        end)
    end)
end

function XUiDormTemplateDetail:Refresh(homeRoomData)
    if homeRoomData then
        self.HomeRoomData = homeRoomData
    end

    self.ConnectId = self.HomeRoomData:GetConnectDormId()
    self.IsConnect = self.ConnectId > 0
    self.RoomId = self.HomeRoomData:GetRoomId()
    self.RoomType = self.HomeRoomData:GetRoomDataType()
    self:RefreshTitle()
    self:RefreshButtons()
    self:RefreshSelectedPanel()
end

function XUiDormTemplateDetail:RefreshTitle()
    if self.IsConnect then
        local prrcent = XDataCenter.DormManager.GetDormTemplatePercent(self.ConnectId, self.RoomId)
        self.TextTitle.text = CS.XTextManager.GetText("DormTemplateTitlePrecnt", prrcent)
        return
    end
    self.TextTitle.text = CS.XTextManager.GetText("DormTemplateTitle")
end

function XUiDormTemplateDetail:RefreshButtons()
    self.DrdSort.gameObject:SetActiveEx(self.IsConnect)
    self.BtnPut.gameObject:SetActiveEx(self.IsConnect)
    if self.IsConnect then
        local name = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId):GetRoomName()
        self.BtnTarget:SetName(name)
    else
        self.BtnTarget:SetName(CS.XTextManager.GetText("DormTemplateTarget"))
    end
end

function XUiDormTemplateDetail:RefreshSelectedPanel()
    if self.SortType == SELECT_TYPE.All then
        self.PageDatas = self.HomeRoomData:GetAllFurnitures()
    elseif self.SortType == SELECT_TYPE.Enough then
        self.PageDatas = self.HomeRoomData:GetEnoughFurnitures()
    elseif self.SortType == SELECT_TYPE.NotEnough then
        self.PageDatas = self.HomeRoomData:GetNotEnoughFurnitures()
    end

    self:SetupDynamicTable()
end

function XUiDormTemplateDetail:InitDynamicTable()
    self.GridTemplateDetail.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridTemplateDetail)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormTemplateDetail:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

-- 动态列表事件
function XUiDormTemplateDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.PageDatas[index]
        grid:Refresh(data)
    end
end

function XUiDormTemplateDetail:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_BUYASSET, self.RefitPanel.UpdateTxtDrawingCount, self.RefitPanel)
    XEventManager.RemoveEventListener(XEventId.EVENT_FURNITURE_GET_FURNITURE, self.RefitPanel.OnGetFurniture, self.RefitPanel)
end