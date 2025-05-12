local XUiDlcMultiPlayerTitleCommon = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

---@class XUiDlcMultiPlayerRoomCuteGrid : XUiNode
---@field ImgReady UnityEngine.UI.Image
---@field ImgModifying UnityEngine.UI.Image
---@field BtnInfo XUiComponent.XUiButton
---@field PanelCountDown UnityEngine.RectTransform
---@field TxtCountDown UnityEngine.UI.Text
---@field ImgMedalIcon UnityEngine.UI.RawImage
---@field PanelChat UnityEngine.RectTransform
---@field PanelDailog UnityEngine.RectTransform
---@field PanelEmoji UnityEngine.RectTransform
---@field TxtDesc UnityEngine.UI.Text
---@field RImgEmoji UnityEngine.UI.RawImage
---@field PanelChatEnable UnityEngine.RectTransform
---@field RImgTitle UnityEngine.UI.RawImage
---@field BtnExchange XUiComponent.XUiButton
---@field BtnKick XUiComponent.XUiButton
---@field ImgView UnityEngine.UI.RawImage
---@field _Control XDlcMultiMouseHunterControl
---@field Parent XUiDlcMultiPlayerRoomCute
local XUiDlcMultiPlayerRoomCuteGrid = XClass(XUiNode, "XUiDlcMultiPlayerRoomCuteGrid")

-- region 生命周期

---@param team XDlcTeam
function XUiDlcMultiPlayerRoomCuteGrid:OnStart(team, index, case)
    self._ChatTimer = nil
    self._Team = team
    self._Index = index
    self._ImgEffect = nil
    self._ImgEffectBlack = nil
    self._TitleGrid = nil
    ---@type XUiPanelRoleModel
    self._RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
    ---@type XSpecialTrainActionRandom
    self._ActionRandom = XSpecialTrainActionRandom.New()

    self:_InitEffect(case)
    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerRoomCuteGrid:OnEnable()
    self:Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiDlcMultiPlayerRoomCuteGrid:OnDisable()
    self:_HideModel()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

-- endregion

-- region 按钮事件

function XUiDlcMultiPlayerRoomCuteGrid:OnBtnExchangeClick()
    local member = self:_GetMember()

    if member then
        local state, matchTime = self.Parent:GetCurrentButtonStateAndMatchTime()

        self._Control:RecordButtonState(state, matchTime)
        self._Control:OpenMatchingPopupUi(matchTime)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CHANGE_UI_SHOW, true)
        XLuaUiManager.Open("UiDlcMultiPlayerExchange", member:GetCharacterId())
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:OnBtnKickClick()
    local selfMember = self._Team:GetSelfMember()

    if not selfMember or not selfMember:IsLeader() then
        return
    end
    if XMVCA.XDlcRoom:IsMatching() then
        return
    end

    self:_DialogKickOut()
end

function XUiDlcMultiPlayerRoomCuteGrid:OnBtnInfoClick()
    local member = self:_GetMember()

    if member and not member:IsSelf() then
        local selfMember = self._Team and self._Team:GetSelfMember() or nil

        if XMVCA.XDlcRoom:IsInRoomMatching() then
            XUiManager.TipText("DlcMultiplayerInMatching")
        elseif selfMember:IsReady() then
            XUiManager.TipText("DlcMultiplayerInReady")
        else
            local _, matchTime = self.Parent:GetCurrentButtonStateAndMatchTime()

            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(member:GetPlayerId(), function()
                self._Control:OpenMatchingPopupUi(matchTime)
            end)
        end
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:OnBtnSkillClick()
    self._Control:OpenUiDlcMultiPlayerSkill(self.Parent._BeginMatchTime)
end

function XUiDlcMultiPlayerRoomCuteGrid:OnMatching()
    self.BtnKick.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerRoomCuteGrid:OnCancelMatching()
    local member = self:_GetMember()
    local isSelf = member:IsSelf()

    self.BtnKick.gameObject:SetActiveEx(not isSelf and self._Team:IsSelfLeader())
end

-- endregion

function XUiDlcMultiPlayerRoomCuteGrid:Refresh(isRedisplay)
    if self:IsEmpty() then
        return
    end
    if self.Parent:IsInChangeState() then
        self:SetModelActive(false)
        self:SetPanelActive(false)
        return
    end

    local member = self:_GetMember()
    local characterId = member:GetCharacterId()
    local isSelf = member:IsSelf()
    local isLeader = member:IsLeader()
    ---@type XDlcMultiMouseHunterPlayerData
    local customData = member:GetCustomData()

    self.BtnInfo.gameObject:SetActiveEx(true)
    self.BtnInfo:SetButtonState(isSelf and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.BtnKick.gameObject:SetActiveEx(not isSelf and self._Team:IsSelfLeader())
    self.BtnExchange.gameObject:SetActiveEx(isSelf)
    self.ImgView.gameObject:SetActiveEx(not isSelf)
    self.ImgMedalIcon.gameObject:SetActiveEx(isLeader)
    self.BtnInfo:SetNameByGroup(0, member:GetName())
    if member:IsSelecting() then
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    elseif member:IsReady() or isLeader then
        self.ImgReady.gameObject:SetActiveEx(true)
        self.ImgModifying.gameObject:SetActiveEx(false)
    else
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    end

    if not isRedisplay then
        self:_StopChatTimer()
    end

    self:RefreshModel(characterId, isRedisplay)
    self:RefreshTitle(customData:GetTitleId())
    self:RefreshSkill()
end

function XUiDlcMultiPlayerRoomCuteGrid:RefreshChat(chatData, receiveTime)
    local isEmoji = chatData.MsgType == ChatMsgType.Emoji
    local leftTime = XFubenConfigs.ROOM_WORLD_TIME
    local nowTime = XTime.GetServerNowTimestamp()

    receiveTime = receiveTime or nowTime
    leftTime = leftTime + receiveTime - nowTime
    if leftTime > 0 then
        if isEmoji then
            local icon = XDataCenter.ChatManager.GetEmojiIcon(chatData.Content)
            self.RImgEmoji:SetRawImage(icon)
        else
            self.TxtDesc.text = chatData.Content or ""
        end

        self:_StopChatTimer()
        self._ChatTimer = XScheduleManager.ScheduleOnce(Handler(self, self._HideChatPanel),
            XScheduleManager.SECOND * leftTime)

        self.PanelChat.gameObject:SetActiveEx(not self.Parent:IsInChangeState())
        self.PanelDailog.gameObject:SetActive(not isEmoji)
        self.PanelEmoji.gameObject:SetActive(isEmoji)
        if not self.Parent:IsInChangeState() then
            self.PanelChatEnable:PlayTimelineAnimation()
        end
    else
        self:_StopChatTimer()
        self.PanelChat.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:RefreshTitle(titleId)
    if XTool.IsNumberValid(titleId) then
        self.RImgTitle.gameObject:SetActiveEx(true)
        if self._TitleGrid then
            self._TitleGrid:Refresh(titleId)
        else
            self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, titleId)
        end
        self._TitleGrid:Open()
    else
        if self._TitleGrid then
            self._TitleGrid:Close()
        else
            self.RImgTitle.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:RefreshSkill()
    local member = self:_GetMember()
    local hasData, skillData = self._Control:TryGetSkillData()
    local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp
    if member:IsSelf() and hasData then
        self.PanelBuff.gameObject:SetActiveEx(true)
        local catConfig = self._Control:GetDlcMultiplayerSkillConfigById(skillData.SelectCatSkillId)
        local mouseConfig = self._Control:GetDlcMultiplayerSkillConfigById(skillData.SelectMouseSkillId)
        self.BtnCatSkill:SetName(catConfig.Name)
        self.BtnCatSkill:SetRawImage(catConfig.Icon)
        self.BtnCatSkill:ShowReddot(self._Control:CheckNewSkillCampRedPoint(CampEnum.Cat))
        self.BtnMouseSkill:SetName(mouseConfig.Name)
        self.BtnMouseSkill:SetRawImage(mouseConfig.Icon)
        self.BtnMouseSkill:ShowReddot(self._Control:CheckNewSkillCampRedPoint(CampEnum.Mouse))
    else
        self.PanelBuff.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:RefreshModelRoot(case)
    self._RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
    self:_InitEffect(case)

    if not self:IsEmpty() then
        local member = self:_GetMember()
        local characterId = member:GetCharacterId()

        self:RefreshModel(characterId)
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:RefreshModel(characterId, isRedisplay)
    self._ActionRandom:Stop()
    self._RoleModel:ShowRoleModel()
    self._Control:UpdateCharacterModelByCharacterId(self._RoleModel, characterId, function()
        self._ActionRandom:SetAnimator(self._RoleModel:GetAnimator(), {}, self._RoleModel)
        self._ActionRandom:Play()
        if self._ImgEffect and not isRedisplay then
            self._ImgEffect.gameObject:SetActiveEx(false)
            self._ImgEffect.gameObject:SetActiveEx(true)
        end
    end, true)
end

function XUiDlcMultiPlayerRoomCuteGrid:SetModelActive(isActive)
    if isActive then
        self._RoleModel:ShowRoleModel()
    else
        self._RoleModel:HideRoleModel()
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:SetPanelActive(isActive)
    if isActive then
        self:Refresh(true)
        self._ImgEffect.gameObject:SetActiveEx(false)
        self._ImgEffectBlack.gameObject:SetActiveEx(false)
        self.PanelChat.gameObject:SetActiveEx(self._ChatTimer ~= nil)
        if self._ChatTimer ~= nil then
            self.PanelChatEnable:PlayTimelineAnimation()
        end
    else
        self.BtnExchange.gameObject:SetActiveEx(false)
        self.BtnInfo.gameObject:SetActiveEx(false)
        self.BtnKick.gameObject:SetActiveEx(false)
        self.ImgView.gameObject:SetActiveEx(false)
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(false)
        self.PanelChat.gameObject:SetActiveEx(false)
        self.PanelBuff.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:IsEmpty()
    local member = self:_GetMember()

    return not member or member:IsEmpty() or not self:IsNodeShow()
end

-- region 私有方法

function XUiDlcMultiPlayerRoomCuteGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchangeClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnBtnInfoClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCatSkill, self.OnBtnSkillClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMouseSkill, self.OnBtnSkillClick)
end

function XUiDlcMultiPlayerRoomCuteGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiDlcMultiPlayerRoomCuteGrid:_RemoveSchedules()
    -- 在此处移除定时器
    self:_StopChatTimer()
end

function XUiDlcMultiPlayerRoomCuteGrid:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA, self.RefreshSkill, self)
end

function XUiDlcMultiPlayerRoomCuteGrid:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA, self.RefreshSkill, self)
end

function XUiDlcMultiPlayerRoomCuteGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiDlcMultiPlayerRoomCuteGrid:_StopChatTimer()
    if self._ChatTimer then
        XScheduleManager.UnSchedule(self._ChatTimer)
        self._ChatTimer = nil
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:_HideChatPanel()
    self._ChatTimer = nil
    self.PanelChat.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerRoomCuteGrid:_HideModel()
    self._RoleModel:HideRoleModel()
    self._ActionRandom:Stop()
end

function XUiDlcMultiPlayerRoomCuteGrid:_GetMember()
    if self._Team and self._Index then
        return self._Team:GetMember(self._Index)
    end

    return nil
end

function XUiDlcMultiPlayerRoomCuteGrid:_InitEffect(case)
    if case then
        self._ImgEffect = case:FindTransform("ImgEffectHuanren")
        self._ImgEffectBlack = case:FindTransform("ImgEffectHuanren1")

        self._ImgEffectBlack.gameObject:SetActiveEx(false)
    end
end

function XUiDlcMultiPlayerRoomCuteGrid:_DialogKickOut()
    local member = self:_GetMember()

    if member then
        local playerId = member:GetPlayerId()
        local title = XUiHelper.GetText("TipTitle")
        local kickOutMassage = XUiHelper.GetText("DlcRoomKickOutTip")

        XUiManager.DialogTip(title, kickOutMassage, XUiManager.DialogType.Normal, nil, function()
            XMVCA.XDlcRoom:KickOut(playerId, Handler(self, self.Close))
        end)
    end
end

-- endregion

return XUiDlcMultiPlayerRoomCuteGrid
