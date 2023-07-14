local XUiMultiplayerRoom = require("XUi/XUiMultiplayerRoom/XUiMultiplayerRoom")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

local XUiMultiplayerRoomCute = XLuaUiManager.Register(XUiMultiplayerRoom, "UiMultiplayerRoomCute")

function XUiMultiplayerRoomCute:Ctor()
    self.SpecialTrainActionRandom = { XSpecialTrainActionRandom.New(), XSpecialTrainActionRandom.New(), XSpecialTrainActionRandom.New() }
    self._IsUpdating = false
end

function XUiMultiplayerRoomCute:OnDisable()
    XUiMultiplayerRoomCute.Super.OnDisable(self)
    for i = 1, #self.SpecialTrainActionRandom do
        self.SpecialTrainActionRandom[i]:Stop()
    end
end

function XUiMultiplayerRoomCute:OnBtnMapsSelectClick()
end

function XUiMultiplayerRoomCute:RefreshButtonStatus(...)
    XUiMultiplayerRoomCute.Super.RefreshButtonStatus(self, ...)
    self.PanelConsume.gameObject:SetActiveEx(false)
    self.PanelLimit.gameObject:SetActiveEx(false)
    self.BtnSpecialEffects.gameObject:SetActiveEx(false)
    self:RefreshHardModeValue()
end

function XUiMultiplayerRoomCute:InitMultiDim(...)
    XUiMultiplayerRoomCute.Super.InitMultiDim(self, ...)
    self.PanelConsume.gameObject:SetActiveEx(false)
end

function XUiMultiplayerRoomCute:OnModelLoadCallback(index, rolePanel)
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    local stageId = roomData.StageId
    if not stageId then
        return
    end
    local needDisplayController = XCharacterCuteConfig.GetNeedDisplayController(stageId)
    if not needDisplayController then
        return
    end
    local actionArray = XCharacterCuteConfig.GetModelRandomAction(rolePanel:GetCurRoleName())
    self.SpecialTrainActionRandom[index]:SetAnimator(rolePanel:GetAnimator(), actionArray, rolePanel)
    self.SpecialTrainActionRandom[index]:Play()
end

function XUiMultiplayerRoomCute:OnModelLoadBegin(index)
    self.SpecialTrainActionRandom[index]:Stop()
end

function XUiMultiplayerRoomCute:InitGridCharData(grid, playerData)
    if not grid then
        return
    end
    self:OnModelLoadBegin(grid.Index)
    grid:InitCharData(playerData, function()
        self:OnModelLoadCallback(grid.Index, grid.RolePanel)
    end)
end

function XUiMultiplayerRoomCute:InitSpecialEffectsButton()
    XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Open)
    XDataCenter.SetManager.SetAllyEffect(true)
end

--region hell mode
function XUiMultiplayerRoomCute:InitDifficultyButtons()
    XUiMultiplayerRoomCute.Super.InitDifficultyButtons(self)
    self:InitHardMode()
end

function XUiMultiplayerRoomCute:UpdateUiHellMode()
    --self.PanelRank.gameObject:SetActiveEx(self.TogHell.isOn)
end

function XUiMultiplayerRoomCute:InitHardMode()
    self:RefreshHardModeValue()
    self:UpdateUiHellMode()
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        if not XDataCenter.FubenSpecialTrainManager.IsCanSelectHellMode(roomData.StageId) then
            self.TogHell.gameObject:SetActiveEx(false)
        else
            self.TogHell.onValueChanged:AddListener(handler(self, self.OnTogHardModeValueChanged))
            self:UpdateHellModeRedDot()
        end
    end
end

function XUiMultiplayerRoomCute:UpdateHellModeRedDot()
    --self.RedHellMode.gameObject:SetActiveEx(XDataCenter.FubenSpecialTrainManager.BreakthroughIsShowRedDotHellMode())
    self.RedHellMode.gameObject:SetActiveEx(false)
end

function XUiMultiplayerRoomCute:RefreshHardModeValue()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    local stageId = roomData.StageId
    if not stageId then
        return
    end
    self._IsUpdating = true
    local isOn = XFubenSpecialTrainConfig.IsHellStageId(stageId)
    self.TogHell.isOn = isOn
    self.MusicHellMode.gameObject:SetActiveEx(isOn)
    self.MusicNormal.gameObject:SetActiveEx(not isOn)
    self._IsUpdating = false
end

function XUiMultiplayerRoomCute:OnTogHardModeValueChanged(value)
    if self._IsUpdating then
        return
    end
    if not XDataCenter.RoomManager.IsLeader(XPlayer.Id) then
        self:RefreshHardModeValue()
        XUiManager.TipText("MultiplayerRoomOnlyHomeownerTip")
        return
    end

    local roomData = XDataCenter.RoomManager.RoomData
    local stageId = roomData and roomData.StageId or false
    if not stageId then
        self.TogHell.isOn = false
        return
    end

    -- 战斗中
    local stateFighting = 1
    if roomData and roomData.State == stateFighting then
        XUiManager.TipCode(20045008)
        self:RefreshHardModeValue()
        return
    end
    
    if value then
        local isCanSelectHellMode = XDataCenter.FubenSpecialTrainManager.IsCanSelectHellMode(stageId, true)

        -- hell mode is lock
        if not isCanSelectHellMode then
            self.TogHell.isOn = false
            self:UpdateUiHellMode()
            return
        end
    end
    self:UpdateUiHellMode()
    XDataCenter.FubenSpecialTrainManager.BreakthroughSetIsHellMode(value)
    stageId = XDataCenter.FubenSpecialTrainManager.BreakthroughGetCurrentStageId()
    XDataCenter.RoomManager.SetStageIdRequest(stageId)
    self:UpdateHellModeRedDot()
end
--endregion hell mode

return XUiMultiplayerRoomCute