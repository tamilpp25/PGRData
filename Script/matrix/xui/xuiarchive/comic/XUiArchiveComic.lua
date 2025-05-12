local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 漫画图鉴目录界面
---@class XUiArchiveComic: XLuaUi
---@field private _Control XArchiveControl
local XUiArchiveComic = XLuaUiManager.Register(XLuaUi, 'UiArchiveComic')

function XUiArchiveComic:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
end

function XUiArchiveComic:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitDynamicTable()
    self:InitTypeButton()
end

function XUiArchiveComic:OnEnable()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveComic:OnDestroy()
    -- 清除所有红点
    self._Control.ComicControl:ClearAllComicGroupRedShow()
end

function XUiArchiveComic:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(require('XUi/XUiArchive/Comic/XUiGridArchiveComic'), self)
    self.DynamicTable:SetDelegate(self)
    self.GridCGItem.gameObject:SetActiveEx(false)
end

function XUiArchiveComic:InitTypeButton()
    self.GroupList = self._Control.ComicControl:GetComicGroupCfgs(true)
    self.CurGroupId = 1
    self.ComicGroupBtnList = {}

    if not XTool.IsTableEmpty(self.GroupList) then
        local timeStamp = XTime.GetServerNowTimestamp()
        
        for _, v in pairs(self.GroupList) do
            if string.IsNilOrEmpty(v.ShowTimeStr) or timeStamp >= XTime.ParseToTimestamp(v.ShowTimeStr) then
                local btn = CS.UnityEngine.GameObject.Instantiate(self.BtnTabShortNew)
                btn.gameObject:SetActive(true)
                btn.transform:SetParent(self.TabBtnContent.transform, false)
                local btncs = btn:GetComponent("XUiButton")
                local name = v.Name
                btncs:SetName(name or "")

                table.insert(self.ComicGroupBtnList, btncs)
                self:InitRedPoint(btncs, v.Id)
            end
        end

        self.TabBtnContent:Init(self.ComicGroupBtnList, function(index) self:SelectType(index) end)
        self.BtnTabShortNew.gameObject:SetActiveEx(false)
        self.TabBtnContent:SelectIndex(self.CurGroupId)
    end
end

function XUiArchiveComic:InitRedPoint(btn, groupId)
    self:AddRedPointEvent(btn,
            function (_,count)
                btn:ShowReddot(count >= 0)
            end, self,
            { XRedPointConditions.Types.CONDITION_ARCHIVE_COMIC_GROUP_RED },
            groupId)
end

function XUiArchiveComic:RefreshCGRateInfo(index)
    self.TxtCollectionDesc.text = self.GroupList[index].Name
    self.RateNum.text = string.format("%d%s", self._Control.ComicControl:GetComicCompletionRate(self.GroupList[index].Id), "%")
end

function XUiArchiveComic:RefreshDynamicTable(groupId)
    self.PageDatas = self._Control.ComicControl:GetComicChapterCfgsByGroupId(groupId)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveComic:SelectType(index)
    self.CurGroupId = index
    self:RefreshCGRateInfo(index)
    self:RefreshDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")

    if self.OldType then
        self._Control.ComicControl:ClearComicGroupRedShow(self.GroupList[self.OldType].Id)
    end

    self.OldType = index
end

function XUiArchiveComic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas, self, index)
        grid:Open()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
    end
end

return XUiArchiveComic