---@class XUiGuildMusicEdit
---@field PanelList UnityEngine.RectTransform
local XUiGuildMusicEdit = XLuaUiManager.Register(XLuaUi, "UiGuildMusicEdit")

function XUiGuildMusicEdit:OnStart()
    self.BgmIds = XTool.Clone(XDataCenter.GuildDormManager.GetBgmIds())
    self:SetExperienceInfo()
    self:InitButtonEvent()
    self:InitDynamicTable()
    self:SetupDynamicTable()
    self.BtnLibraryEventId = XRedPointManager.AddRedPointEvent(self.BtnLibrary, self.OnClickBtnLibraryRedPoint, self, { XRedPointConditions.Types.CONDITION_GUILD_DORM_BGM })
end

function XUiGuildMusicEdit:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_TOPPING_BGM, self.OnToppingBgm, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_DELETE_BGM, self.OnDeleteBgm, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_UPDATE_BGM_LIST, self.OnUpdateBgmList, self)
end

function XUiGuildMusicEdit:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_TOPPING_BGM, self.OnToppingBgm, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_DELETE_BGM, self.OnDeleteBgm, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_UPDATE_BGM_LIST, self.OnUpdateBgmList, self)
end

function XUiGuildMusicEdit:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.BtnLibraryEventId)
end

function XUiGuildMusicEdit:InitButtonEvent()
    self.BtnSave.CallBack = function()
        if self:CheckEditBgmId() then
            return
        end
        XDataCenter.GuildDormManager.GuildDormSetRoomBgmIdsRequest(self.BgmIds,function()
            XUiManager.TipText("GuildDormMusicEditSaveSuccess")
            self:Close()
        end)
    end
    self.BtnLibrary.CallBack = function()
        if self:CheckEditBgmId() then
            return
        end
        XLuaUiManager.Open("UiGuildMusicLibrary",self.BgmIds, function(bgmIds)
            self.BgmIds = bgmIds
            self:SetExperienceInfo()
            self:SetupDynamicTable()
        end)
    end
    self.BtnTanchuangCloseBig.CallBack = function()
        if self:CheckEditBgmId() then
            return
        end
        XUiManager.DialogTip(CS.XTextManager.GetText("GuildDormMusicEditCloseTitle"),CS.XTextManager.GetText("GuildDormMusicEditCloseContent"),XUiManager.DialogType.Normal,function() 
            self:Close()
        end,function()
            XDataCenter.GuildDormManager.GuildDormSetRoomBgmIdsRequest(self.BgmIds,function()
                XUiManager.TipText("GuildDormMusicEditSaveSuccess")
                self:Close()
            end)
        end)
    end
end

function XUiGuildMusicEdit:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiGuildDorm/MusicPlayer/XUiGridGuildMusicEdit"))
end

function XUiGuildMusicEdit:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self.BgmIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuildMusicEdit:OnDynamicTableEvent(event,index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local bgmId = self.BgmIds[index]
        grid:Refresh(index, bgmId, self.BgmExperience[bgmId])
    end
end

function XUiGuildMusicEdit:OnToppingBgm(index, bgmId)
    table.remove(self.BgmIds, index)
    table.insert(self.BgmIds, 1, bgmId)
    self:SetupDynamicTable()
end

function XUiGuildMusicEdit:OnDeleteBgm(index)
    if #self.BgmIds == 1 then
        XUiManager.TipText("GuildMusicEditDeleteTip")
        return
    end
    table.remove(self.BgmIds, index)
    self:SetupDynamicTable()
end

function XUiGuildMusicEdit:OnUpdateBgmList()
    self.BgmIds = XTool.Clone(XDataCenter.GuildDormManager.GetBgmIds())
    self:SetExperienceInfo()
    self:SetupDynamicTable()
end

function XUiGuildMusicEdit:OnClickBtnLibraryRedPoint(count)
    self.BtnLibrary:ShowReddot(count >= 0)
end

function XUiGuildMusicEdit:CheckEditBgmId()
    local isExpire = XDataCenter.GuildDormManager.RemoveExperienceExpireBgmId(self.BgmIds)
    if isExpire then
        XUiManager.TipText("GuildDormBgmEditExperienceExpire")
        self:SetupDynamicTable()
        return true
    end
    return false
end

function XUiGuildMusicEdit:SetExperienceInfo()
    self.BgmExperience = {}
    for _, bgmId in pairs(self.BgmIds or {}) do
        -- 体验中
        local isExperience = XDataCenter.GuildDormManager.CheckExperienceTimeIdByBgmId(bgmId)
        self.BgmExperience[bgmId] = isExperience
    end
end

return XUiGuildMusicEdit
