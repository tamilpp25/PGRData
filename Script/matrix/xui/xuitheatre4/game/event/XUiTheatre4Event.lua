local XUiTheatre4EventOption = require("XUi/XUiTheatre4/Game/Event/XUiTheatre4EventOption")
local XUiTheatre4EventReward = require("XUi/XUiTheatre4/Game/Event/XUiTheatre4EventReward")
local XUiTheatre4EventConfirm = require("XUi/XUiTheatre4/Game/Event/XUiTheatre4EventConfirm")
---@class XUiTheatre4Event : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Event = XLuaUiManager.Register(XLuaUi, "UiTheatre4Event")

function XUiTheatre4Event:OnAwake()
    self:RegisterUiEvents()
    self.PanelGoldChange.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelConfirm.gameObject:SetActiveEx(false)
    self.PanelOption.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
    self.BtnBack.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
end

---@param gridData XTheatre4Grid
---@param callback function 回调
---@param cancelCallback function 取消回调
function XUiTheatre4Event:OnStart(eventId, mapId, gridData, fateUid, callback, cancelCallback)
    self.EventId = eventId
    self.FateUid = fateUid
    self.MapId = mapId
    self.GridData = gridData
    self.Callback = callback
    self.CancelCallback = cancelCallback
end

function XUiTheatre4Event:OnEnable()
    self:Refresh()
end

function XUiTheatre4Event:Refresh()
    self:RefreshGold()
    self:RefreshCharacterInfo()
    self:RefreshEventInfo()
    self:RefreshEventOptionInfo()
end

function XUiTheatre4Event:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
    }
end

function XUiTheatre4Event:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshGold()
    end
end

function XUiTheatre4Event:OnDestroy()
    if self.CancelCallback then
        self.CancelCallback()
    end
end

-- 刷新金币
function XUiTheatre4Event:RefreshGold()
    -- 金币图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if icon then
        self.RImgGold:SetRawImage(icon)
    end
    -- 金币数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

-- 刷新角色信息
function XUiTheatre4Event:RefreshCharacterInfo()
    local roleIcon = self._Control:GetEventRoleIcon(self.EventId)
    if roleIcon then
        self.PanelRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(roleIcon)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
        return
    end
    self.TxtRoleName.text = self._Control:GetEventRoleName(self.EventId)
    self.TxtRoleContent.text = self._Control:GetEventRoleContent(self.EventId)
    local roleEffect = self._Control:GetEventRoleEffect(self.EventId)
    if roleEffect then
        self.RoleEffect.gameObject:LoadUiEffect(roleEffect)
    end
end

-- 刷新事件信息
function XUiTheatre4Event:RefreshEventInfo()
    local bgAsset = self._Control:GetEventBgAsset(self.EventId)
    self.Background.gameObject:SetActiveEx(bgAsset ~= nil)
    local isForcePlay = self._Control:CheckEventForcePlay(self.EventId)
    self.BtnBack.gameObject:SetActiveEx(bgAsset ~= nil and not isForcePlay)
    if bgAsset then
        self.Background:SetRawImage(bgAsset)
    end
    self.TxtTitle.text = self._Control:GetEventTitle(self.EventId)
    self.TxtContent.text = self._Control:GetEventTitleContent(self.EventId)
end

-- 刷新事件选项信息
function XUiTheatre4Event:RefreshEventOptionInfo()
    local eventType = self._Control:GetEventType(self.EventId)
    if eventType == XEnumConst.Theatre4.EventType.Dialogue then
        self:OpenDialogue()
    elseif eventType == XEnumConst.Theatre4.EventType.Options then
        self:OpenOptions()
    elseif eventType == XEnumConst.Theatre4.EventType.Reward then
        self:OpenReward()
    elseif eventType == XEnumConst.Theatre4.EventType.Fight then
        self:OpenDialogue()
    else
        XLog.Error("XUiTheatre4Event:RefreshEventOptionInfo error, eventType is nil")
    end
end

-- 显示对话
function XUiTheatre4Event:OpenDialogue()
    self:CloseOptions()
    self:CloseReward()
    if not self.PanelConfirmUi then
        ---@type XUiTheatre4EventConfirm
        self.PanelConfirmUi = XUiTheatre4EventConfirm.New(self.PanelConfirm, self)
    end
    self.PanelConfirmUi:Open()
    self.PanelConfirmUi:Refresh(self.EventId)
end

-- 关闭对话
function XUiTheatre4Event:CloseDialogue()
    if self.PanelConfirmUi then
        self.PanelConfirmUi:Close()
    end
end

-- 显示选项
function XUiTheatre4Event:OpenOptions()
    self:CloseDialogue()
    self:CloseReward()
    if not self.PanelOptionUi then
        ---@type XUiTheatre4EventOption
        self.PanelOptionUi = XUiTheatre4EventOption.New(self.PanelOption, self)
    end
    self.PanelOptionUi:Open()
    self.PanelOptionUi:Refresh(self.EventId)
end

-- 关闭选项
function XUiTheatre4Event:CloseOptions()
    if self.PanelOptionUi then
        self.PanelOptionUi:Close()
    end
end

-- 显示奖励
function XUiTheatre4Event:OpenReward()
    self:CloseDialogue()
    self:CloseOptions()
    if not self.PanelRewardUi then
        ---@type XUiTheatre4EventReward
        self.PanelRewardUi = XUiTheatre4EventReward.New(self.PanelReward, self)
    end
    self.PanelRewardUi:Open()
    self.PanelRewardUi:Refresh(self.EventId)
end

-- 关闭奖励
function XUiTheatre4Event:CloseReward()
    if self.PanelRewardUi then
        self.PanelRewardUi:Close()
    end
end

-- 处理事件
function XUiTheatre4Event:HandleEvent(optionId)
    -- 没有选项默认为0
    if not optionId then
        optionId = 0
    end
    if XTool.IsNumberValid(self.MapId) then
        local posX, posY = self.GridData:GetGridPos()
        self._Control:DoGridEventRequest(self.MapId, posX, posY, optionId, function()
            local nextEventId = self.GridData:GetGridEventId()
            self:AfterHandleEvent(nextEventId)
        end)
    else
        self._Control:DoFateEventRequest(optionId, self.FateUid, function()
            local isFateExist, fate = self._Control:IsFateExist(self.FateUid)
            if isFateExist and fate then
                self:AfterHandleEvent(fate:GetEventId())
            else
                -- 如果当前命运, 已经不存在, 则关闭
                self:AfterHandleEvent()
            end
        end)
    end
end

-- 请求事件后回调
function XUiTheatre4Event:AfterHandleEvent(nextEventId)
    if self._Control:CheckEventEnd(self.EventId) then
        -- 事件主动结束
        self:Close()
        return
    end
    if XTool.IsNumberValid(nextEventId) then
        if self:IsBattleEvent(nextEventId) then
            -- 进入战斗
            self:EnterBattle()
            return
        end
        -- 有下一个事件 直接刷新
        self.EventId = nextEventId
        self:Refresh()
        -- 检查是否有弹框 强制播放时不检查
        if not self._Control:CheckEventForcePlay(nextEventId) then
            self._Control:CheckNeedOpenNextPopup()
        end
    else
        -- 没有下一个事件 关闭界面
        XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
    end
end

-- 检查是否是战斗事件
function XUiTheatre4Event:IsBattleEvent(nextEventId)
    local eventType = self._Control:GetEventType(nextEventId)
    return eventType == XEnumConst.Theatre4.EventType.Fight
end

-- 进入战斗
function XUiTheatre4Event:EnterBattle()
    if XTool.IsNumberValid(self.MapId) then
        local stageId = self.GridData:GetGridEventStageId()
        local posX, posY = self.GridData:GetGridPos()
        self._Control:BeforeOpenBattlePanel(self.Name, stageId, self.MapId, posX, posY)
    else
        local stageId = self._Control:GetFateTriggerStageId(self.FateUid)
        self._Control:BeforeOpenBattlePanel(self.Name, stageId)
    end
end

-- 获得关卡得分
function XUiTheatre4Event:GetStageScore()
    if XTool.IsNumberValid(self.MapId) then
        return self.GridData:GetGridEventStageScore()
    else
        return self._Control:GetFateTriggerStageScore(self.FateUid)
    end
end

function XUiTheatre4Event:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
end

function XUiTheatre4Event:OnBtnCloseClick()
    -- 检查是否强制播放
    if self._Control:CheckEventForcePlay(self.EventId) then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS)
    self:Close()
end

function XUiTheatre4Event:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

return XUiTheatre4Event
