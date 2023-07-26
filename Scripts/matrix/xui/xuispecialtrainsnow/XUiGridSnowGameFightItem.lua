local XUiGridSnowGameFightItem = XClass(nil, "XUiGridSnowGameFightItem")
local XUiGridSnowGameDataItem = require("XUi/XUiSpecialTrainSnow/XUiGridSnowGameDataItem")

local playerIndex = 1

function XUiGridSnowGameFightItem:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
    
    self:SwitchDisabledLike()
    self.DataItemNames = {
        XUiHelper.GetText("SnowGameFightDataItemName1"),
        XUiHelper.GetText("SnowGameFightDataItemName2"),
        XUiHelper.GetText("SnowGameFightDataItemName3"),
    }
end

function XUiGridSnowGameFightItem:GetDataItemNames()
    return self.DataItemNames
end

--举报
function XUiGridSnowGameFightItem:OnBtnReportClick()
    if self.IsAlreadyReport then
        return
    end
    XUiManager.TipText("ReportFinish")
    self.BtnReport.ButtonState = CS.UiButtonState.Disable
    self.IsAlreadyReport = true
end
--点赞
function XUiGridSnowGameFightItem:OnBtnLikeClick()
    XDataCenter.RoomManager.AddLike(self.PlayerData.Id)
    self:SwitchAlreadyLike()
end
--加好友
function XUiGridSnowGameFightItem:OnBtnAddFriendClick()
    XDataCenter.SocialManager.ApplyFriend(self.PlayerData.Id)
end

function XUiGridSnowGameFightItem:RefreshPlayerData(data)
    self.PlayerData = data
    local medalConfig = XMedalConfigs.GetMeadalConfigById(self.PlayerData.MedalId)
    local medalIcon
    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    if medalIcon ~= nil then
        self.ImgMedalIcon:SetRawImage(medalIcon)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
    else
        self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end
    
    local character = self.PlayerData.Character
    local headInfo = character.CharacterHeadInfo or {}
    local headIcon = self:GetHeadIcon(character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
    self.RImgIcon:SetRawImage(headIcon)
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(self.PlayerData.Id, self.PlayerData.Name)

    self.GridFightDataList = {}
    for index, name in ipairs(self:GetDataItemNames()) do
        local item = CS.UnityEngine.GameObject.Instantiate(self.GridFightDataItem, self.PanelFightDataContainer)
        local grid = XUiGridSnowGameDataItem.New(item, name)
        self.GridFightDataList[index] = grid
    end
    self.GridFightDataItem.gameObject:SetActiveEx(false)

    self.IsPlayer = self.PlayerData.Id == XPlayer.Id
    if self.IsPlayer then
        self:SwitchMyself()
        self.Transform:SetSiblingIndex(playerIndex)
    else
        self:SwitchNormal()
    end
end

function XUiGridSnowGameFightItem:RefreshDataItem(data)
    if data then
        if self.ImgMvp then
            self.ImgMvp.gameObject:SetActiveEx(data.IsRankingMvp)
        end
        self.GridFightDataList[1]:Refresh(false, data.StageScore)
        self.GridFightDataList[2]:Refresh(false, data.KillCount)
        self.GridFightDataList[3]:Refresh(false, data.Score)
    else
        if self.ImgMvp then
            self.ImgMvp.gameObject:SetActiveEx(false)
        end
        for _, grid in pairs(self.GridFightDataList) do
            grid:Refresh(false, 0)
        end
    end
end

function XUiGridSnowGameFightItem:SwitchNormal()
    self.PanelOperation.gameObject:SetActiveEx(true)
    self.TxtMyself.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(true)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridSnowGameFightItem:SwitchMyself()
    self.PanelOperation.gameObject:SetActiveEx(false)
    self.TxtMyself.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridSnowGameFightItem:SwitchDisabledLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(true)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridSnowGameFightItem:SwitchAlreadyLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridSnowGameFightItem:GetHeadIcon(characterId, ...)
    --return XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, ...)
    return XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(characterId)
end

return XUiGridSnowGameFightItem