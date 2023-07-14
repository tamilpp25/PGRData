local XUiMultiplayerRoom = require("XUi/XUiMultiplayerRoom/XUiMultiplayerRoom")
local XUiMultiplayerRoomCute = XLuaUiManager.Register(XUiMultiplayerRoom, "UiMultiplayerRoomCute")
local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")

function XUiMultiplayerRoomCute:Ctor()
    self.SpecialTrainActionRandom = {XSpecialTrainActionRandom.New(), XSpecialTrainActionRandom.New(), XSpecialTrainActionRandom.New()}
end

function XUiMultiplayerRoomCute:OnDisable()
    XUiMultiplayerRoomCute.Super.OnDisable(self)
    for i = 1,#self.SpecialTrainActionRandom do
        self.SpecialTrainActionRandom[i]:Stop()
    end
end

function XUiMultiplayerRoomCute:RefreshButtonStatus()
    XUiMultiplayerRoomCute.Super.RefreshButtonStatus(self)
    self.BtnMapSelect.gameObject:SetActiveEx(true)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        self.TxtMap.text = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    end
end

function XUiMultiplayerRoomCute:OnBtnMapsSelectClick()
end

function XUiMultiplayerRoomCute:RefreshButtonStatus(...)
    XUiMultiplayerRoomCute.Super.RefreshButtonStatus(self, ...)
    self.PanelConsume.gameObject:SetActiveEx(false)
    self.PanelLimit.gameObject:SetActiveEx(false)
    self.BtnSpecialEffects.gameObject:SetActiveEx(false)
end

function XUiMultiplayerRoomCute:InitMultiDim(...)
    XUiMultiplayerRoomCute.Super.InitMultiDim(self, ...)
    self.PanelConsume.gameObject:SetActiveEx(false)    
end

function XUiMultiplayerRoomCute:OnModelLoadCallback(index, rolePanel)
    local actionArray = XFubenSpecialTrainConfig.GetModelRandomAction(rolePanel:GetCurRoleName())
    self.SpecialTrainActionRandom[index]:SetAnimator(rolePanel:GetAnimator(), actionArray, rolePanel)
    self.SpecialTrainActionRandom[index]:Play()
end

function XUiMultiplayerRoomCute:OnModelLoadBegin(index)
    self.SpecialTrainActionRandom[index]:Stop()
end

function XUiMultiplayerRoomCute:InitGridCharData(grid, charData)
    self:OnModelLoadBegin(grid.Index)
    grid:InitCharData(charData, function()
        self:OnModelLoadCallback(grid.Index, grid.RolePanel)
    end)
end

function XUiMultiplayerRoomCute:InitGridCharData(grid, playerData)
    self:OnModelLoadBegin(grid.Index)
    grid:InitCharData(playerData, function()
        self:OnModelLoadCallback(grid.Index, grid.RolePanel)
    end)
end

function XUiMultiplayerRoomCute:InitSpecialEffectsButton()
    XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Open)
    XDataCenter.SetManager.SetAllyEffect(true)
end

return XUiMultiplayerRoomCute