local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildMusicLibrary = XLuaUiManager.Register(XLuaUi, "UiGuildMusicLibrary")

function XUiGuildMusicLibrary:OnStart(bgmIds, closeCb)
    self.CloseCb = closeCb
    self.BgmIds = bgmIds or {}
    self:InitButtonEvent()
    self:InitDynamicTable()
    self:SetupDynamicTable()
end

function XUiGuildMusicLibrary:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_SELECT_BGM, self.OnClickGrid, self)
end

function XUiGuildMusicLibrary:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_SELECT_BGM, self.OnClickGrid, self)
end

function XUiGuildMusicLibrary:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiGuildDorm/MusicPlayer/XUiGridGuildMusicLibrary"))
end

function XUiGuildMusicLibrary:SetupDynamicTable()
    local bgmList = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.BGM)
    self.AllBgmList = {}
    for _, bgmCfg in pairs(bgmList) do
        if bgmCfg.NeedBuy == 0 then
            table.insert(self.AllBgmList, { Id = bgmCfg.Id })
        end
    end
    local buyedBgm = XDataCenter.GuildManager.GetDormBgms()
    for _, bgmId in pairs(buyedBgm) do
        table.insert(self.AllBgmList, { Id = bgmId})
    end
    -- 体验bgm
    for _, bgmCfg in pairs(bgmList) do
        if bgmCfg.NeedBuy == 1 and XTool.IsNumberValid(bgmCfg.ExperienceTimeId) then
            local isInTime = XFunctionManager.CheckInTimeByTimeId(bgmCfg.ExperienceTimeId)
            local isBoughtBgm = table.contains(buyedBgm, bgmCfg.Id)
            if not isBoughtBgm and isInTime then
                table.insert(self.AllBgmList, { Id = bgmCfg.Id, IsExperience = true })
            end
        end
    end
    XLog.Debug("aafasou ",self.AllBgmList)
    self.DynamicTable:SetDataSource(self.AllBgmList)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuildMusicLibrary:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local bgmId = self.AllBgmList[index].Id
        local isSelect, _ = self:IsSelect(bgmId)
        grid:Refresh(self.AllBgmList[index], isSelect)
    end
end

function XUiGuildMusicLibrary:InitButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:OnClose()
    end
    self.BtnTanchuangCloseBig.CallBack = function()
        self:OnClose()
    end

    self.BtnClose.CallBack = function()
        self:OnClose()
    end
end

function XUiGuildMusicLibrary:IsSelect(bgmId)
    for i, id in ipairs(self.BgmIds) do
        if id == bgmId then
            return true, i
        end
    end
    return false
end

---@param grid XUiGridGuildMusicLibrary
function XUiGuildMusicLibrary:OnClickGrid(bgmId, grid)
    if grid.IsExperience then
        local isExpire = XDataCenter.GuildDormManager.CheckExperienceExpireByBgmId(bgmId)
        if isExpire then
            XUiManager.TipText("GuildDormBgmExperienceExpire")
            XDataCenter.GuildDormManager.RemoveExperienceExpireBgmId(self.BgmIds)
            self:SetupDynamicTable()
            return
        end
    end
    local isSelect, index = self:IsSelect(bgmId)
    if isSelect then
        table.remove(self.BgmIds, index)
    else
        table.insert(self.BgmIds, bgmId)
    end
    grid:SetGridState(not isSelect)
end

function XUiGuildMusicLibrary:OnClose()
    local isExpire = XDataCenter.GuildDormManager.RemoveExperienceExpireBgmId(self.BgmIds)
    if isExpire then
        XUiManager.TipText("GuildDormBgmExperienceExpire")
        self:SetupDynamicTable()
    else
        self:Close()
        if self.CloseCb then
            self.CloseCb(self.BgmIds)
        end
    end
end

return XUiGuildMusicLibrary