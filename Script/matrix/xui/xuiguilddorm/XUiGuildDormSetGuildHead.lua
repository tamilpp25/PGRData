--===============
--公会宿舍设置头像界面
--===============
local XUiGuildDormSetGuildHead = XLuaUiManager.Register(XLuaUi, "UiGuildDormHeadPotrait")
local XUiGuildHeadPortraitItem = require("XUi/XUiGuild/XUiChildItem/XUiGuildHeadPortraitItem")

function XUiGuildDormSetGuildHead:OnAwake()
    self:InitButtons()
    self.CurHeadPortraitId = -1
    self.InitHeadPortraitId = 1
    self:InitDynamicTable()
    self:SetListDatas()
    self:UpdateInfo(XDataCenter.GuildManager.GetGuildHeadPortrait())
end

function XUiGuildDormSetGuildHead:InitButtons()
    self.BtnHeadSure.CallBack = function() self:OnBtnHeadSureClick() end
    self.BtnHeadCancel.CallBack = function() self:OnBtnHeadCancelClick() end
    self.BtnClose.CallBack = function() self:OnBtnHeadCancelClick() end
end

function XUiGuildDormSetGuildHead:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiGuildHeadPortraitItem)
    self.DynamicTable:SetDelegate(self)
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormSetGuildHead:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListDatas[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSeleGridItem then
            self.CurSeleGridItem:SetStatus(false)
        end

        local data = self.ListDatas[index]
        grid:SetStatus(true)
        self.CurSeleGridItem = grid
        self:UpdateInfo(data.Id)
    end
end

function XUiGuildDormSetGuildHead:IsSeleId(id)
    return self.CurHeadPortraitId == id
end

function XUiGuildDormSetGuildHead:UpdateInfo(id)
    if self.CurHeadPortraitId == id then
        return
    end

    self.CurHeadPortraitId = id
    local config = XGuildConfig.GetGuildHeadPortraitById(id)
    self.RImgPlayerIcon:SetRawImage(config.Icon)
    self.TxtHeadName.text = config.Name
    self.TxtDecs.text = config.Describe
end

function XUiGuildDormSetGuildHead:SetListDatas()
    self.ListDatas = XGuildConfig.GetGuildHeadPortraitDatas()
    self.DynamicTable:SetDataSource(self.ListDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiGuildDormSetGuildHead:OnBtnHeadSureClick()
    local curHeadPortrait = XDataCenter.GuildManager.GetGuildHeadPortrait()
    if self.CurHeadPortraitId ~= curHeadPortrait then
        XDataCenter.GuildManager.GuildChangeIconRequest(self.CurHeadPortraitId, function()
                local config = XGuildConfig.GetGuildHeadPortraitById(self.CurHeadPortraitId)
                self:OnBtnHeadCancelClick()
            end)
    end
end

function XUiGuildDormSetGuildHead:RecordFirstSeleItem(item)
    self.CurSeleGridItem = item
end

function XUiGuildDormSetGuildHead:OnBtnHeadCancelClick()
    self:Close()
end