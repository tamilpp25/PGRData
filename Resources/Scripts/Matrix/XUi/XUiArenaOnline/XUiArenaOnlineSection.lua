local XUiArenaOnlineSection = XLuaUiManager.Register(XLuaUi, "UiArenaOnlineSection")
local XUiSectionPrefab = require("XUi/XUiArenaOnline/XUiSectionPrefab")
local XUiPanelStageDetail = require("XUi/XUiArenaOnline/XUiPanelStageDetail")

function XUiArenaOnlineSection:OnAwake()
    self:AutoAddListener()
end

function XUiArenaOnlineSection:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.DetailPanel = XUiPanelStageDetail.New(self, self.PanelDetail, function()
        self.AssetPanel.GameObject:SetActiveEx(false)
    end, function()
        self.AssetPanel.GameObject:SetActiveEx(true)
    end)

    local sectionCfg = XDataCenter.ArenaOnlineManager.GetCurSectionCfg()
    if not sectionCfg then return end

    local prefabpath = XDataCenter.ArenaOnlineManager.GetCurSectionPrefabPath()
    if prefabpath then
        self.Resource = CS.XResourceManager.Load(prefabpath)
    end
    local prefab = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
    prefab.transform:SetParent(self.PanelCase, false)
    prefab.gameObject:SetLayerRecursively(self.PanelCase.gameObject.layer)

    self.SectionGrid = XUiSectionPrefab.New(prefab, self)
end

function XUiArenaOnlineSection:OpenStageDetial(stageId)
    self.DetailPanel:Show(stageId)
end

function XUiArenaOnlineSection:OnEnable()
    if self.SectionGrid then
        self.SectionGrid:OnEnable()
    end

    if self.DetailPanel then
        self.DetailPanel:Refresh(true)
    end

    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_DAY_REFRESH, self.OnArenaOnlineDayRefrsh, self)
end

function XUiArenaOnlineSection:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_DAY_REFRESH, self.OnArenaOnlineDayRefrsh, self)
end

-- 区域联机周刷新
function XUiArenaOnlineSection:OnArenaOnlineWeekRefrsh()
    XDataCenter.ArenaOnlineManager.RunMain()
end

-- 区域联机日刷新
function XUiArenaOnlineSection:OnArenaOnlineDayRefrsh()
    local refresh = XDataCenter.ArenaOnlineManager.CheckCurSectionDayRefrsh()
    if not refresh then return end

    XUiManager.TipMsg(CS.XTextManager.GetText("ArenaOnlineDayTimeOut"))
    if XDataCenter.RoomManager.Matching then
        XDataCenter.RoomManager.CancelMatch(function()
            self.DetailPanel:OnCancelMatch()
            self:Close()
        end)
    else
        self:Close()
    end
end

function XUiArenaOnlineSection:OnDestroy()
    if self.Resource then
        self.Resource:Release()
    end

    if self.SectionGrid then
        self.SectionGrid:OnDestroy()
        CS.UnityEngine.Object.Destroy(self.SectionGrid.GameObject)
    end
end

function XUiArenaOnlineSection:OnHideDetail()
    self.DetailPanel:Hide()
end

function XUiArenaOnlineSection:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end

function XUiArenaOnlineSection:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaOnlineSection:OnCancelMatch()
    self.DetailPanel:OnCancelMatch()
end

function XUiArenaOnlineSection:EnterRoom()
    self.DetailPanel:ResetState()
end

function XUiArenaOnlineSection:OnBtnBackClick()
    if XDataCenter.RoomManager.Matching then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.CancelMatch(function()
                self:Close()
            end)
        end)
    else
        self:Close()
    end
end