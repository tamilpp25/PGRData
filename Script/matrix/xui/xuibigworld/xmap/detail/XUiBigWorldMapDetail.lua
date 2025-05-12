local XUiSGGridItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldMapDetail : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnOperate XUiComponent.XUiButton
---@field PanelIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field PanelName UnityEngine.RectTransform
---@field TxtStoryDes UnityEngine.UI.Text
---@field PanelProgress XUiComponent.XUiTextGroup
---@field PanelReward UnityEngine.RectTransform
---@field PanelItem UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field ProgressList UnityEngine.RectTransform
---@field _Control XBigWorldMapControl
local XUiBigWorldMapDetail = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMapDetail")

local OperatorType = {
    Track = 0,
    Teleport = 1,
    CancelTrack = 2,
}

-- region 生命周期

function XUiBigWorldMapDetail:OnAwake()
    ---@type XBWMapPinData
    self._PinData = nil
    ---@type XUiGridBWItem[]
    self._RewardGrids = {}
    self._ProgerssGrids = {}

    self.BtnClose.gameObject:SetActiveEx(false)
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapDetail:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMapDetail:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMapDetail:OnDestroy()

end

-- endregion

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:Refresh(levelId, pinData)
    self._LevelId = levelId
    self._PinData = pinData

    self:_Refresh()
end

-- region 按钮事件

function XUiBigWorldMapDetail:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldMapDetail:OnBtnOperateClick()
    if self._PinData then
        local pinData = self._PinData

        self:OnPinClick(pinData.TeleportEnable and pinData:IsActive(), pinData.PinId, pinData.TeleportPosition,
            pinData.TeleportEulerAngleY)
    end
end

function XUiBigWorldMapDetail:OnPinClick(isTeleportEnable, pinId, teleportPosition, teleportEulerAngleY)
    if isTeleportEnable then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT, teleportPosition, teleportEulerAngleY)
    else
        if self._Control:CheckCurrentTrackPin(self._LevelId, pinId) then
            self._Control:CancelTrackPin(self._LevelId, pinId)
        else
            self._Control:TrackPin(self._LevelId, pinId)
        end
    end
end

function XUiBigWorldMapDetail:OnRefresh()
    self:_Refresh()
end

-- endregion

-- region 私有方法

function XUiBigWorldMapDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnOperate, self.OnBtnOperateClick, true)
end

function XUiBigWorldMapDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMapDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMapDetail:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMapDetail:_Refresh()
    if self._PinData then
        if self._PinData:IsQuest() then
            self:_RefreshQuest(self._PinData.QuestId)
        elseif self._PinData:IsActivity() then
            self:_RefreshActivity(self._PinData.ActivityId)
        else
            self:_RefreshPin()
        end
    end
end

function XUiBigWorldMapDetail:_RefreshPin()
    local isActive = self._PinData:IsActive()

    self.TxtTitle.text = self._PinData.Name or ""
    self.TxtStoryDes.text = self._PinData.Desc or ""
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinDesc")
    self:_RefreshPinStyle(self._PinData.StyleId, isActive)
    self:_RefreshPinOperator(isActive and self._PinData.TeleportEnable)
    self:_RefreshProgress()
    self:_RefreshReward()
end

function XUiBigWorldMapDetail:_RefreshPinOperator(isTeleport)
    if isTeleport then
        self:_RefreshOperatorText(OperatorType.Teleport)
    else
        if self._Control:CheckCurrentTrackPin(self._LevelId, self._PinData.PinId) then
            self:_RefreshOperatorText(OperatorType.CancelTrack)
        else
            self:_RefreshOperatorText(OperatorType.Track)
        end
    end
end

function XUiBigWorldMapDetail:_RefreshPinStyle(styleId, isActive)
    if XTool.IsNumberValid(styleId) then
        if isActive then
            self.PanelIcon:SetSprite(self._Control:GetPinActiveIconByStyleId(styleId))
        else
            self.PanelIcon:SetSprite(self._Control:GetPinActiveIconByStyleId(styleId))
        end
    end
end

function XUiBigWorldMapDetail:_RefreshQuest(questId)
    local rewardId = XMVCA.XBigWorldQuest:GetQuestRewardId(questId)
    local displayProgress = XMVCA.XBigWorldQuest:GetQuestDisplayProgress(questId)
    local progressText = {}

    if not XTool.IsTableEmpty(displayProgress) then
        for _, progress in ipairs(displayProgress) do
            table.insert(progressText, ((progress.Title or "") .. (progress.Progress or "")))
        end
    end

    self.PanelIcon:SetSprite(XMVCA.XBigWorldQuest:GetQuestIcon(questId))
    self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
    self.TxtStoryDes.text = XMVCA.XBigWorldQuest:GetQuestStepText(questId) or ""
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinQuestDesc")
    self:_RefreshPinOperator(false)
    self:_RefreshProgress(progressText)
    self:_RefreshReward(rewardId)
end

function XUiBigWorldMapDetail:_RefreshActivity(activityId)

end

function XUiBigWorldMapDetail:_RefreshOperatorText(operatorType)
    self.BtnOperate:ActiveTextByGroup(OperatorType.Track, operatorType == OperatorType.Track)
    self.BtnOperate:ActiveTextByGroup(OperatorType.CancelTrack, operatorType == OperatorType.CancelTrack)
    self.BtnOperate:ActiveTextByGroup(OperatorType.Teleport, operatorType == OperatorType.Teleport)
end

function XUiBigWorldMapDetail:_RefreshReward(rewardId)
    if XTool.IsNumberValid(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)

        self.PanelReward.gameObject:SetActiveEx(false)
        for i, reward in pairs(rewardList) do
            local grid = self._RewardGrids[i]

            if not grid then
                local ui = i == 1 and self.ItemGrid or XUiHelper.Instantiate(self.ItemGrid, self.PanelReward)

                grid = XUiSGGridItem.New(ui, self)
                self._RewardGrids[i] = grid
            end

            grid:Open()
            grid:Refresh(reward)
        end
        for i = #rewardList + 1, #self._RewardGrids do
            self._RewardGrids[i]:Close()
        end
    else
        for _, grid in pairs(self._RewardGrids) do
            grid:Close()
        end
        self.PanelReward.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMapDetail:_RefreshProgress(progressList)
    if not XTool.IsTableEmpty(progressList) then
        self.ProgressList.gameObject:SetActiveEx(true)
        for i, progress in pairs(progressList) do
            local grid = self._ProgerssGrids[i]

            if not grid then
                grid = i == 1 and self.PanelProgress or XUiHelper.Instantiate(self.PanelProgress, self.ProgressList)

                self._ProgerssGrids[i] = grid
            end

            grid:SetName(progress)
        end
        for i = #progressList + 1, #self._ProgerssGrids do
            self._ProgerssGrids[i].gameObject:SetActiveEx(false)
        end
    else
        self.ProgressList.gameObject:SetActiveEx(false)
    end
end

-- endregion

return XUiBigWorldMapDetail
