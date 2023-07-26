local XUiGridSummerEpisodeSettleItem = XClass(nil, "UiGridSummerEpisodeSettleItem")
local XUiGridFightDataItem = require("XUi/XUiSummerEpisode/Settle/XUiGridSummerEpisodeSettleDataItem")

function XUiGridSummerEpisodeSettleItem:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
end

function XUiGridSummerEpisodeSettleItem:OnBtnReportClick()
    if self.IsAlreadyReport then
        return
    end
    XUiManager.TipText("ReportFinish")
    self.BtnReport.ButtonState = CS.UiButtonState.Disable
    self.IsAlreadyReport = true
end

function XUiGridSummerEpisodeSettleItem:OnBtnLikeClick()
    self.Parent:OnAddLike(self.PlayerData.Id)
end

function XUiGridSummerEpisodeSettleItem:OnBtnAddFriendClick()
    self.Parent:OnApplyFriend(self.PlayerData.Id)
end

function XUiGridSummerEpisodeSettleItem:Init(playerData, playerCount, stageId)
    local medalConfig = XMedalConfigs.GetMeadalConfigById(playerData.MedalId)
    local medalIcon = nil
    if medalConfig then
        medalIcon = medalConfig.MedalIcon
    end
    if medalIcon ~= nil then
        self.ImgMedalIcon:SetRawImage(medalIcon)
        self.ImgMedalIcon.gameObject:SetActiveEx(true)
    else
    self.ImgMedalIcon.gameObject:SetActiveEx(false)
    end

    self.PlayerData = playerData
    local character = playerData.Character
    local headInfo = character.CharacterHeadInfo or {}
    local headIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
    self.RImgIcon:SetRawImage(headIcon)
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(playerData.Id, playerData.Name)
    local isArenaOnline = playerData.StageType and playerData.StageType == XDataCenter.FubenManager.StageType.ArenaOnline
    local isPass = playerData.HaveFirstPass and playerCount > 1
    self.PanelArenaOnline.gameObject:SetActiveEx(isArenaOnline and isPass)

    local item1 = CS.UnityEngine.GameObject.Instantiate(self.GridFightDataItem, self.PanelFightDataContainer)
    --2.6 只有合作模式
    --[[
    local IsPeaceModel = XFubenSpecialTrainConfig.IsHellStageId(stageId)
    local mischiefText = IsPeaceModel and CSXTextManagerGetText("SummerEpisodeWorkingScore") or CSXTextManagerGetText("SummerEpisodeMischiefScore")
    --]]
    local mischiefText=CSXTextManagerGetText("SummerEpisodeWorkingScore")
    self.GridFightDataList = {
        XUiGridFightDataItem.New(self.GridFightDataItem, CSXTextManagerGetText("SummerEpisodePhotoScore")),
        XUiGridFightDataItem.New(item1, mischiefText),
    }
end

function XUiGridSummerEpisodeSettleItem:Refresh(dpsData)
    if dpsData then
        self.GridFightDataList[1]:Refresh(dpsData.IsPhotoMvp, dpsData.ScorePhoto)
        self.GridFightDataList[2]:Refresh(dpsData.IsMischiefMvp, dpsData.ScoreByMischief)
    else
        self.GridFightDataList[1]:Refresh(false, 0)
        self.GridFightDataList[2]:Refresh(false, 0)
    end
end

function XUiGridSummerEpisodeSettleItem:SwitchNormal()
    self.PanelOperation.gameObject:SetActiveEx(true)
    self.TxtMyself.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(true)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridSummerEpisodeSettleItem:SwitchMyself()
    self.PanelOperation.gameObject:SetActiveEx(false)
    self.TxtMyself.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridSummerEpisodeSettleItem:SwitchDisabledLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(true)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridSummerEpisodeSettleItem:SwitchAlreadyLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
end

return XUiGridSummerEpisodeSettleItem