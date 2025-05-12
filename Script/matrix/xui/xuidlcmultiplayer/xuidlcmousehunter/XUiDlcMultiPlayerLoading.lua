local XUiDlcMultiPlayerLoadingItem = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerLoadingItem")

---@class XUiDlcMultiPlayerLoading : XLuaUi
---@field TxtTips UnityEngine.UI.Text
---@field LoadingPlayerItem UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field UpperLineLoadingDetail UnityEngine.RectTransform
---@field LowerLineLoadingDetail UnityEngine.RectTransform
---@field TxtTitle UnityEngine.UI.Text
---@field RawImageBg UnityEngine.UI.RawImage
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerLoading = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerLoading")

-- region 生命周期

function XUiDlcMultiPlayerLoading:OnAwake()
    self._Tips = self._Control:GetLoadingTips()
    self._TipsTimer = nil
    self._CurrentTipIndex = 1
    self._CurrentFinishCount = 0
    self._AllPlayerCount = 0
    ---@type table<number, XUiDlcMultiPlayerLoadingItem>
    self._OnLoadingItemMap = {}

    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerLoading:OnStart()
    self:_InitItemList()
end

function XUiDlcMultiPlayerLoading:OnEnable()
    self:_RefreshTips()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiDlcMultiPlayerLoading:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiDlcMultiPlayerLoading:OnDestroy()

end

-- endregion

function XUiDlcMultiPlayerLoading:RefreshFinishCount()
    if self._CurrentFinishCount > self._AllPlayerCount then
        self._CurrentFinishCount = self._AllPlayerCount
    end

    self.TxtNum.text = "(" .. self._CurrentFinishCount .. "/" .. self._AllPlayerCount .. ")"
    self._CurrentFinishCount = self._CurrentFinishCount + 1
end

-- region 私有方法

function XUiDlcMultiPlayerLoading:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiDlcMultiPlayerLoading:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RegisterTipsTimer()
end

function XUiDlcMultiPlayerLoading:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveTipsTimer()
end

function XUiDlcMultiPlayerLoading:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_FIGHT_LOADING, self._RefreshProcess, self)
    if XMVCA.XDlcRoom:IsReconnect() then
        XEventManager.AddEventListener(XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS, self._RefreshProcess, self)
    end
end

function XUiDlcMultiPlayerLoading:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_FIGHT_LOADING, self._RefreshProcess, self)
    if XMVCA.XDlcRoom:IsReconnect() then
        XEventManager.RemoveEventListener(XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS, self._RefreshProcess, self)
    end
end

function XUiDlcMultiPlayerLoading:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiDlcMultiPlayerLoading:_InitItemList()
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()
    local worldData = not fightBeginData:IsWorldClear() and fightBeginData:GetWorldData() or nil
    local playerDataList = worldData and worldData:GetPlayerDataList() or {}
    local playerCount = #playerDataList
    local middle = math.ceil(playerCount / 2)

    for i, playerData in pairs(playerDataList) do
        local item = nil
        
        if i <= middle then
            item = XUiHelper.Instantiate(self.LoadingPlayerItem.gameObject, self.UpperLineLoadingDetail)
        else
            item = XUiHelper.Instantiate(self.LoadingPlayerItem.gameObject, self.LowerLineLoadingDetail)
        end

        local itemObject = XUiDlcMultiPlayerLoadingItem.New(item, self, playerData)

        self._OnLoadingItemMap[playerData:GetPlayerId()] = itemObject
    end

    self.TxtTitle.text = self._Control:GetCurrentWorldArtName()
    self.RawImageBg:SetRawImage(self._Control:GetCurrentWorldLoadingBackground())
    self.LoadingPlayerItem.gameObject:SetActiveEx(false)
    self._AllPlayerCount = playerCount
    self:_InitProgress()
    self:RefreshFinishCount()
end

function XUiDlcMultiPlayerLoading:_RefreshTips()
    if self._CurrentTipIndex > #self._Tips then
        self._CurrentTipIndex = 1
    end

    self.TxtTips.text = self._Tips[self._CurrentTipIndex] or ""
    self._CurrentTipIndex = self._CurrentTipIndex + 1
end

function XUiDlcMultiPlayerLoading:_RefreshProcess(playerId, progress)
    local item = self._OnLoadingItemMap[playerId]

    if not item then
        return
    end

    item:RefreshProgress(progress)
end

function XUiDlcMultiPlayerLoading:_InitProgress()
    if XMVCA.XDlcRoom:IsReconnect() then
        for playerId, item in pairs(self._OnLoadingItemMap) do
            if playerId ~= XPlayer.Id then
                item:RefreshProgress(100)
            end
        end
    end
end

function XUiDlcMultiPlayerLoading:_RegisterTipsTimer()
    self:_RemoveTipsTimer()

    if not XTool.IsTableEmpty(self._Tips) then
        local interval = self._Control:GetLoadingTipsScrollingTime()

        self._TipsTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshTips),
            interval * XScheduleManager.SECOND)
    end
end

function XUiDlcMultiPlayerLoading:_RemoveTipsTimer()
    if self._TipsTimer then
        XScheduleManager.UnSchedule(self._TipsTimer)
        self._TipsTimer = nil
    end
end

-- endregion

return XUiDlcMultiPlayerLoading
