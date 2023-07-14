local XUiGuildPerson = XLuaUiManager.Register(XLuaUi, "UiGuildPerson")
local XUiGridGuildGiftItem = require("XUi/XUiGuild/XUiChildItem/XUiGridGuildGiftItem")
local XUiGuildViewCharacterFilter = require("XUi/XUiGuild/XUiChildView/XUiGuildViewCharacterFilter")
local TextManager = CS.XTextManager
function XUiGuildPerson:OnAwake()
    self.ListData = {}
    self.CurRecordIds = {}
    self:Init()
end

function XUiGuildPerson:OnStart()
end

function XUiGuildPerson:OnEnable()
    self.CurIdCount = 0
    self:OnRefresh()
end


function XUiGuildPerson:OnDisable()
    self.CurRecordIds = {}
    self.IsAllRecord = false
end

function XUiGuildPerson:OnDestroy()
end

function XUiGuildPerson:OnRefresh()
    self:OnRefreshListData()
    self:SetCurGiftName()
end

function XUiGuildPerson:Init()
    self:InitList()
    self:InitFun()
    self.UiGuildViewCharacterFilter = XUiGuildViewCharacterFilter.New(self.PanelCharacterFiltrate,self)
    local text = TextManager.GetText("GuildGiftBtnDes")
    self.BtnFilter:SetNameByGroup(0,text)
    self.TxtNone.text = TextManager.GetText("GuildGiftEmptyDes")
    self.TotalReqcount = XGuildConfig.GetGuildWishMaxCountByLevel(XDataCenter.GuildManager.GetGuildLevel())
    self:SetCurGiftReqCount()
end

function XUiGuildPerson:InitList()
    self.DynamicShopTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicShopTable:SetProxy(XUiGridGuildGiftItem)
    self.DynamicShopTable:SetDelegate(self)
end

-- 设置当前角色礼物请求数
function XUiGuildPerson:SetCurGiftReqCount()
    local curcount = XDataCenter.GuildManager.GetCurWishReqCount()
    self.RequestCountTxt.text = TextManager.GetText("GuildGiftReqTxtDes",curcount,self.TotalReqcount)
end

-- 设置当前角色礼物对应名字
function XUiGuildPerson:SetCurGiftName()
    if next(self.CurRecordIds) and self.CurIdCount == 1 then
        self.ShowScreen.gameObject:SetActiveEx(true)
        local name = XCharacterConfigs.GetCharacterName(self.CurSeleId)
        self.TxtName.text = TextManager.GetText("GuildGiftNameDes",name)
    else
        self.ShowScreen.gameObject:SetActiveEx(false)
    end
end

function XUiGuildPerson:OnRefreshListData()
    if next(self.CurRecordIds) and not self.IsAllRecord then
        self.ListData = {}
        local dic = {}
        for _,charId in pairs(self.CurRecordIds)do
            local d = XGuildConfig.GetTrustItemsByCharacterId(charId) or {}
            if next(d) then
                for _,id in pairs(d)do
                    dic[id] = id
                end
            end
        end
        for _,itemid in pairs(dic)do
            table.insert( self.ListData, {Id = itemid})
        end

		 for index,v in pairs(self.ListData)do
            if self.CurRecordIds[v.Id] then
                table.remove(self.ListData, index)
            end
        end
    else
        self.ListData = XGuildConfig.GetGuildTrustItemsList() or {}
    end


    self.DynamicShopTable:SetDataSource(self.ListData)
    self.DynamicShopTable:ReloadDataASync()
    local flag = #self.ListData <= 0
    self.ImgNonePerson.gameObject:SetActiveEx(flag)
end

function XUiGuildPerson:InitFun()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnFilter.CallBack = function() self:OnBtnFilter() end
end

function XUiGuildPerson:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListData[index])
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiGuildPerson:OnBtnAll()
    for gridIndex,griddata in pairs(self.ListData)do
        local grid = self.DynamicShopTable:GetGridByIndex(gridIndex)
        if grid then
            grid:SetSeleStatus(true)
        end
        griddata.Status = true
    end
end

function XUiGuildPerson:OnBtnTanchuangClose()
    self:Close()
end

function XUiGuildPerson:OnBtnFilter()
    self.PanelRewards.gameObject:SetActiveEx(false)
    self.UiGuildViewCharacterFilter:OnEnable()
end

function XUiGuildPerson:RecordSeleId(id)
    if id and not self.CurRecordIds[id] then
        self.CurSeleId = id
        self.CurRecordIds[id] = id
        self.CurIdCount = self.CurIdCount + 1
    end
end

function XUiGuildPerson:RemoveRecordSeleId(id)
    if id and self.CurRecordIds[id] then
        self.CurRecordIds[id] = nil
        self.CurIdCount = self.CurIdCount - 1
    end
end

function XUiGuildPerson:AllRecordSeleId()
    self.IsAllRecord = true
end