---@class XUiDlcCasualGameLoading : XLuaUi
---@field PanelOnLineLoadingDetail UnityEngine.RectTransform
---@field RImgBoss UnityEngine.UI.RawImage
---@field TxtTips UnityEngine.UI.Text
---@field PanelOnLineLoadingDetailItem UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualGameLoading = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGameLoading")
local XUiDlcCasualGameLoadingItem = require("XUi/XUiDlcCasualGame/XUiDlcCasualGameLoadingItem")

function XUiDlcCasualGameLoading:Ctor()
    ---@type XUiDlcCasualGameLoadingItem[]
    self._OnLoadingItemList = {}
    self._Timer = nil
    self._Tips = nil
    self._TipsIndex = 1
end

function XUiDlcCasualGameLoading:OnAwake()
    self:_InitItemList()
    self._Tips = self._Control:GetLoadingTips()
end

function XUiDlcCasualGameLoading:OnEnable()
    self:_StartTimer()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_FIGHT_LOADING, self._RefreshProcess, self)
end

function XUiDlcCasualGameLoading:OnDisable()
    self:_StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_FIGHT_LOADING, self._RefreshProcess, self)
end

function XUiDlcCasualGameLoading:OnDestroy()
    self._OnLoadingItemList = nil
end

function XUiDlcCasualGameLoading:_InitItemList()
    ---@type XDlcRoomAgency
    local agency = XMVCA:GetAgency(ModuleId.XDlcRoom)
    local playerDataList = agency:GetRoomData():GetPlayerDataList()

    XTool.LoopCollection(playerDataList, function(data)
        local item = XUiHelper.Instantiate(self.PanelOnLineLoadingDetailItem.gameObject, self.PanelOnLineLoadingDetail)

        self._OnLoadingItemList[data:GetPlayerId()] = XUiDlcCasualGameLoadingItem.New(item, self, data)
    end)
    self.PanelOnLineLoadingDetailItem.gameObject:SetActiveEx(false)
end

function XUiDlcCasualGameLoading:_RefreshProcess(playerId, progress)
    local item = self._OnLoadingItemList[playerId]

    if not item then
        return
    end
    
    item:RefreshProgress(progress)
end

function XUiDlcCasualGameLoading:_StartTimer()
    local interval = tonumber(self._Control:GetOtherConfigValueByKeyAndIndex("LoadingTipsTime"))

    self:_StopTimer()

    if XTool.IsTableEmpty(self._Tips) then
        self.TxtTips.text = ""
        return
    end
    
    self._Timer = XScheduleManager.ScheduleForeverEx(Handler(self, self._ShowTips), interval * XScheduleManager.SECOND)
end

function XUiDlcCasualGameLoading:_StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiDlcCasualGameLoading:_ShowTips()
    if self._TipsIndex > #self._Tips then
        self._TipsIndex = 1
    end

    self.TxtTips.text = self._Tips[self._TipsIndex]
    self._TipsIndex = self._TipsIndex + 1
end

return XUiDlcCasualGameLoading