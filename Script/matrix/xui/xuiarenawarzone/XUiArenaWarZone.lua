local XUiArenaWarZone = XLuaUiManager.Register(XLuaUi, "UiArenaWarZone")

local XUiGridZone = require("XUi/XUiArenaWarZone/ArenaWarZoneCommon/XUiGridZone")

function XUiArenaWarZone:OnAwake()
    self:AutoAddListener()
end


function XUiArenaWarZone:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.GridList = {}
    for i = 1, 6 do
        local trans = self["GridZone" .. i]
        local grid = XUiGridZone.New(trans, self)
        table.insert(self.GridList, grid)
    end
end


function XUiArenaWarZone:OnEnable()
    XDataCenter.ArenaManager.RequestAreaData()
    self:Refresh()
end

function XUiArenaWarZone:OnGetEvents()
    return { XEventId.EVENT_ARENA_REFRESH_AREA_INFO, XEventId.EVENT_ARENA_UNLOCK_AREA }
end

function XUiArenaWarZone:OnNotify(evt)
    if evt == XEventId.EVENT_ARENA_REFRESH_AREA_INFO then
        self:Refresh()
    elseif evt == XEventId.EVENT_ARENA_UNLOCK_AREA then
        self:RefreshUnlockCount()
    end
end

function XUiArenaWarZone:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.BtnBuff.CallBack = function() 
        self:OnClickBtnBuff()
    end
    self:BindHelpBtn(self.BtnHelpCourse, "Arena")
end

function XUiArenaWarZone:OnBtnBackClick()
    self:Close()
end

function XUiArenaWarZone:OnClickBtnBuff()
    XLuaUiManager.Open("UiArenaBuffTips",XDataCenter.ArenaManager.GetGroupFightEvent())
end

function XUiArenaWarZone:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaWarZone:Refresh()
    local point = XDataCenter.ArenaManager.GetArenaAreaTotalPoint()
    self.TxtTotalPoint.text = point
    self:RefreshUnlockCount()
    local currEvent = XDataCenter.ArenaManager.GetGroupFightEvent()
    self.BtnBuff.gameObject:SetActiveEx(currEvent ~= 0)
    local challengeCfg = XDataCenter.ArenaManager.GetCurChallengeCfg()
    for _, grid in pairs(self.GridList) do
        grid:SetGridClose()
    end
    for _, groupStr in pairs(challengeCfg.AreaIdGroup) do
        local areaIdList = string.Split(groupStr,"|")
        for _, areaIdStr in pairs(areaIdList) do
            local areaId = tonumber(areaIdStr)
            local areaData = XDataCenter.ArenaManager.GetArenaAreaDataByAreaId(areaId)
            local areaStageCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(areaId)
            self.GridList[areaStageCfg.Region]:SetMetaData(areaId)
            if areaData then
                break
            end
        end
    end
end

function XUiArenaWarZone:RefreshUnlockCount()
    local remainCount = XDataCenter.ArenaManager.GetUnlockArenaAreaCount()
    self.TxtRemainUnlockTime.text = remainCount
end