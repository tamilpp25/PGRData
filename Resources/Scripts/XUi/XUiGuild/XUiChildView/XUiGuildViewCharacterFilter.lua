local XUiGuildViewCharacterFilter = XClass(nil, "XUiGuildViewCharacterFilter")
local XUiGridGuildPersonItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildPersonItem")


function XUiGuildViewCharacterFilter:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.ListData = {}
    self.CurRecordIds = {}
    self:Init()
end

function XUiGuildViewCharacterFilter:OnStart()
end

function XUiGuildViewCharacterFilter:OnEnable()
    self.GameObject:SetActiveEx(true)
    self:OnRefreshListData()
end

function XUiGuildViewCharacterFilter:OnDisable()
    self.CurRecordIds = {}
end

function XUiGuildViewCharacterFilter:OnDestroy()

end

function XUiGuildViewCharacterFilter:Init()
    self:InitList()
    self:InitFun()
end

function XUiGuildViewCharacterFilter:InitList()
    self.DynamicShopTable = XDynamicTableNormal.New(self.PanelList.gameObject)
    self.DynamicShopTable:SetProxy(XUiGridGuildPersonItem)
    self.DynamicShopTable:SetDelegate(self)
end

function XUiGuildViewCharacterFilter:OnRefreshListData()
    self.ListData = XGuildConfig.GetTrustCharacterIds() or {}
    self.DynamicShopTable:SetDataSource(self.ListData)
    self.DynamicShopTable:ReloadDataASync()
    local flag = #self.ListData <= 0
    self.ImgNonePerson.gameObject:SetActiveEx(flag)
end

function XUiGuildViewCharacterFilter:InitFun()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirm() end
    self.BtnAll.CallBack = function() self:OnBtnAll() end
end

function XUiGuildViewCharacterFilter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListData[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClickSeleStatus()
    end
end

function XUiGuildViewCharacterFilter:OnBtnAll()
    for gridIndex,griddata in pairs(self.ListData)do
        local grid = self.DynamicShopTable:GetGridByIndex(gridIndex)
        if grid then
            grid:SetSeleStatus(true)
        end
        griddata.Status = true
    end
    self:AllRecordSeleId(true)
end

function XUiGuildViewCharacterFilter:OnBtnTanchuangClose()
    self.GameObject:SetActiveEx(false)
    self.UiRoot.PanelRewards.gameObject:SetActiveEx(true)
    self.UiRoot:OnRefresh()
end

function XUiGuildViewCharacterFilter:OnBtnConfirm()
    self:OnBtnTanchuangClose()
end

function XUiGuildViewCharacterFilter:RecordSeleId(id)
    self.UiRoot:RecordSeleId(id)
end

function XUiGuildViewCharacterFilter:RemoveRecordSeleId(id)
    self.UiRoot:RemoveRecordSeleId(id)
end

function XUiGuildViewCharacterFilter:AllRecordSeleId()
    self.UiRoot:AllRecordSeleId()
end

return XUiGuildViewCharacterFilter