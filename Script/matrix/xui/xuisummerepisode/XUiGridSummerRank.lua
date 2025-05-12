local XUiGridSummerRank = XClass(nil, "XUiGridSummerRank")

local stringOther = "<color=#FFFFFF>%s</color>"
local stringSelf = "<color=#000000>%s</color>"

function XUiGridSummerRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.BtnAdd.CallBack = function()
        self:OnBtnAddFriendClick()
    end

    self.BtnTipOff.CallBack = function()
        self:OnBtnReport()
    end
end

function XUiGridSummerRank:Refresh(playerData, index)
    local player = playerData.Player
    self.PlayerData = player

    local isSelf = player.Id == XPlayer.Id
    self.PanelSelf.gameObject:SetActiveEx(isSelf)

    XUiPlayerHead.InitPortrait(player.HeadPortraitId, player.HeadFrameId, self.Head)
    
    local colorFormat = stringOther
    if isSelf then
        colorFormat = stringSelf
    end

    self.TxtName.text = string.format(colorFormat, XDataCenter.SocialManager.GetPlayerRemark(player.Id, player.Name))

    if playerData.RankType == XFubenSpecialTrainConfig.StageType.Broadsword then
        self.TxtTime.gameObject:SetActiveEx(false)
        self.Txtkill.gameObject:SetActiveEx(true)
        self.Txtkill.text = string.format(colorFormat, playerData.Count)
        if playerData.Count and playerData.Count ~= 0 then
            self.Txtkill.gameObject:SetActiveEx(true)
        else
            self.Txtkill.gameObject:SetActiveEx(false)
        end
    elseif playerData.RankType == XFubenSpecialTrainConfig.StageType.Alive then
        
        self.Txtkill.gameObject:SetActiveEx(false)
        self.TxtTime.text = string.format(colorFormat, XUiHelper.GetTime(playerData.Time, XUiHelper.TimeFormatType.TOWER_RANK))
        if playerData.Time and playerData.Time ~= 0 then
            self.TxtTime.gameObject:SetActiveEx(true)
        else
            self.TxtTime.gameObject:SetActiveEx(false)
        end
    elseif playerData.RankType == XFubenSpecialTrainConfig.StageType.Music then
        self.Txtkill.gameObject:SetActiveEx(false)
        self.TxtTime.gameObject:SetActiveEx(false)
    end

    self.TxtOrder.text = string.format(colorFormat, index)
    if index == 1 then
        self.TxtOrderName.text = string.format(colorFormat, "st")
    elseif index == 2 then
        self.TxtOrderName.text = string.format(colorFormat, "nd")
    elseif index == 3 then
        self.TxtOrderName.text = string.format(colorFormat, "rd")
    else
        self.TxtOrderName.text = string.format(colorFormat, "th")
    end

    self.TxtKillDesc.text = string.format(colorFormat, self.TxtKillDesc.text)
    self.TxtTimeDesc.text = string.format(colorFormat, self.TxtTimeDesc.text)
    self.TxtKillDesc1.text = string.format(colorFormat, self.TxtKillDesc1.text)

    self.BtnAdd.gameObject:SetActiveEx(not XDataCenter.SocialManager.CheckIsFriend(self.PlayerData.Id))
end

-- 加好友
function XUiGridSummerRank:OnBtnAddFriendClick()
    if self.IsAddFriend then
        return
    end

    self.IsAddFriend = true

    XDataCenter.SocialManager.ApplyFriend(self.PlayerData.Id, function()
        self.BtnAdd.ButtonState = CS.UiButtonState.Disable
    end)
end

--举报
function XUiGridSummerRank:OnBtnReport()

    if self.IsReport then
        return
    end

    local dataTemp = {Id = self.PlayerData.Id, TitleName = self.PlayerData.Name, PlayerLevel = self.PlayerData.Level}
    XLuaUiManager.Open("UiReport", dataTemp, nil, function()
        self.BtnTipOff.ButtonState = CS.UiButtonState.Disable
        self.IsReport = true
    end)
end

return XUiGridSummerRank