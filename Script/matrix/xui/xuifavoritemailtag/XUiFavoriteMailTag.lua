local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiFavoriteMailTag : XLuaUi
---@field _Control XMailControl
local XUiFavoriteMailTag = XLuaUiManager.Register(XLuaUi, "UiFavoriteMailTag")
local XUIGridFavorMail = require("XUi/XUiFavoriteMailTag/XUIGridFavorMail") --XUIGridFavorMail,
local CSGetText = CS.XTextManager.GetText

function XUiFavoriteMailTag:OnAwake()
    self.SelectedTagIndex = 1  --当前选择的Tag
    self.SelectedTagData = nil --当前选择Tag的数据
    self.FavorMailDatas = {} --当前Tag下需要显示的邮件列表
    self.SelectedMailIndex = 1 --当前选择的邮件
    self.SelectedMailData = nil --当前选择邮件的数据
    self.GridItem.gameObject:SetActiveEx(false)
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self:InitDynamicTable()
    if self.HtxtMailContent.HrefListener then
        self.HtxtMailContent.HrefListener = function(link) self:ClickLink(link) end
    end
    if self.HtxtMailContent.onLinkClick then
        self.HtxtMailContent.onLinkClick = function(arg) self:ClickLink(arg) end
    end
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAssetitems, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFavoriteMailTag:OnStart()
    self._Control:SetUICollectBoxViewedRedPoint()
    self.RewardGrids = {} --显示奖励的Grid
    self:UpdateCollectionTabsView()
end

function XUiFavoriteMailTag:OnEnable()
end

function XUiFavoriteMailTag:OnDisable() 
    self:RemoveTimer()
end

--==========Tag Begin============
function XUiFavoriteMailTag:UpdateCollectionTabsView()
    local datas = self._Control:GetNotEmptyCollectionTagsData()
    local buttons = {}
    XUiHelper.RefreshCustomizedList(self.PanelTabGroup.transform, self.BtnTab, #datas, function(index, go)
        local button = go:GetComponent("XUiButton")
        local data = datas[index]
        go.name = "BtnTab"..data.EnName
        button:SetNameByGroup(0, string.format("%02d",index))
        button:SetNameByGroup(1, data.TagName) 
        button:SetNameByGroup(2, data.EnName)
        button:SetDisable(false)
        table.insert(buttons, button)
    end)
    self.PanelTabGroup:Init(buttons, function(index) self:OnBtnTagClicked(index,datas[index]) end)
    if #datas > 0 then
        self.PanelTabGroup:SelectIndex(self.SelectedTagIndex)
    else
        self:OnBtnTagClicked(0,nil)
    end
end
function XUiFavoriteMailTag:OnBtnTagClicked(index,data)
    self.SelectedTagIndex = index
    self.SelectedTagData = data
    if self.SelectedTagData then
        self.ImgTagBG:SetRawImage(data.TagBg)
        self.ImgTagImage:SetRawImage(data.TagImage)
        self.SelectedMailIndex = 1
        self.FavorMailDatas = self._Control:GetCollectBoxMailsByTag(data.Id)
    end
    self:UpdateMailListView()
    self:PlayAnimation("QieHuan2")
end
--==========Tag End============

--==========邮件列表 Begin===========
function XUiFavoriteMailTag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMailList)
    self.DynamicTable:SetProxy(XUIGridFavorMail)
    self.DynamicTable:SetDelegate(self)
    self.GridMail.gameObject:SetActive(false)
end
function XUiFavoriteMailTag:UpdateMailListView()
    if not self.SelectedTagData then
        self.PanelMailList.gameObject:SetActiveEx(false)
        self.SelectedMailIndex = 0
        self.SelectedMailData = nil
    else
        self.PanelMailList.gameObject:SetActiveEx(true)
        self.SelectedMailData = self.FavorMailDatas[self.SelectedMailIndex]
        self.DynamicTable:SetDataSource(self.FavorMailDatas)
        self.DynamicTable:ReloadDataSync(1)
    end
        self:UpdateMailContainView()
end
function XUiFavoriteMailTag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateView(self,self.FavorMailDatas[index],function() self:OnBtnMailClicked(index) end)
        grid.index = index
        grid:SetSelect(index == self.SelectedMailIndex)
    end
end
function XUiFavoriteMailTag:OnBtnMailClicked(index)
    self.SelectedMailIndex = index
    for k,grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetSelect(k == index)
    end
    self.SelectedMailData = self.FavorMailDatas[self.SelectedMailIndex]
    self:UpdateMailContainView()
    self:PlayAnimation("QieHuan1")
end
--==========邮件列表 End===========

--==========邮件内容 Begin========
function XUiFavoriteMailTag:UpdateMailContainView()
    if not self.SelectedMailData then
        self.HtxtMailContent.text = ""
        self.TxtMailTitle.text = ""
        self.TxtMailDate.text = ""
        self:UpdateMailRewardList({})
    else
        self.HtxtMailContent.text = XUiHelper.ConvertLineBreakSymbol(self.SelectedMailData.Content) .. "\n\n" .. CSGetText("ComeFrom") .. ": " .. self.SelectedMailData.SendName .. "\n"
        self.TxtMailTitle.text = self.SelectedMailData.Title
        self.TxtMailDate.text = CsXTextManagerGetText("CollectionBoxFavorMailTime",self.SelectedMailData.ShowTime)
        self:UpdateMailRewardList(self.SelectedMailData.RewardIds)
    end
end
function XUiFavoriteMailTag:UpdateMailRewardList(rewardList)
    for _, grid in pairs(self.RewardGrids) do
        grid:Refresh()
    end
    if #rewardList <= 0 then
        self.PanelContentReward.gameObject:SetActiveEx(false)
        return 
    end
    self.PanelContentReward.gameObject:SetActiveEx(true)
    local index = 1
    local function refreshReward(value)
        if not self.RewardGrids[index] then
            local item = CS.UnityEngine.Object.Instantiate(self.GridItem)
            item.gameObject:SetActiveEx(true)
            local grid = XUiGridCommon.New(self, item)
            grid.Transform:SetParent(self.PanelItemContent, false)
            self.RewardGrids[index] = grid
        end
        self.RewardGrids[index]:Refresh(value, { ["ShowReceived"] = true })
        index = index + 1
    end
    
    local rewardDatas = {}
    for _,v in pairs(rewardList) do
        local rDatas  = XRewardManager.GetRewardList(v)
        for _,reward in pairs(rDatas) do
            table.insert(rewardDatas,reward)
        end
    end

    for i = 1, #rewardDatas do
        refreshReward(rewardDatas[i])
    end
end
--==========邮件内容 End========

--==========按钮事件Begin===========
function XUiFavoriteMailTag:OnBtnBackClick()
    self._Control:SyncMailEvent()
    self:Close()
end
function XUiFavoriteMailTag:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--==========按钮事件End===========


function XUiFavoriteMailTag:ClickLink(url)
    CS.UnityEngine.Application.OpenURL(url)
end
function XUiFavoriteMailTag:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end