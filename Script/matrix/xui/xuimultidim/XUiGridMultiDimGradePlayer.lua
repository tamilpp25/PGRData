local XUiGridMultiDimGradePlayer = XClass(nil,"XUiGrideMultiDimGradePlayer")
local XUiGridMultiDimGradeDataItem = require("XUi/XUiMultiDim/XUiGridMultiDimGradeDataItem")

function XUiGridMultiDimGradePlayer:Ctor(transform,parent)
    self.Transform = transform
    self.GameObject = transform.GameObject
    self.Parent = parent
    self.LikeCount = 0
    XTool.InitUiObject(self)
    self.GridFightDataList ={
        [1] =  XUiGridMultiDimGradeDataItem.New(self.PanelDataScore),
        [2] = XUiGridMultiDimGradeDataItem.New(self.PanelDataGrade),
        [3] = XUiGridMultiDimGradeDataItem.New(self.PanelDataFever)
    }
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
end

function XUiGridMultiDimGradePlayer:OnBtnReportClick()
    if self.IsAlreadyReport then
        return
    end
    XUiManager.TipText("ReportFinish")
    self.BtnReport.ButtonState = CS.UiButtonState.Disable
    self.IsAlreadyReport = true
end

function XUiGridMultiDimGradePlayer:OnBtnLikeClick()
    self.Parent:OnAddLike(self.PlayerData.Id)
end

function XUiGridMultiDimGradePlayer:OnBtnAddFriendClick()
    XDataCenter.SocialManager.ApplyFriend(self.PlayerData.Id)
end

function XUiGridMultiDimGradePlayer:RefreshPlayerData(playerData)
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
    if playerData.Id == XPlayer.Id then
        self:SwitchMyself()
    end
end

function XUiGridMultiDimGradePlayer:RefreshDataItem(data)
    if data then
        self.GridFightDataList[1]:Refresh(data.IsScoreMvp, data.Score)
        self.GridFightDataList[2]:Refresh(false, XUiHelper.GetTime(data.UseTime))
        self.GridFightDataList[3]:Refresh(data.IsDamageMvp, data.DamageTotal)
    else
        for _, grid in pairs(self.GridFightDataList) do
            grid:Refresh(false, 0)
        end
    end
end

function XUiGridMultiDimGradePlayer:SwitchNormal()
    self.PanelOperation.gameObject:SetActiveEx(true)
    self.TxtMyself.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(true)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridMultiDimGradePlayer:SwitchMyself()
    self.PanelOperation.gameObject:SetActiveEx(false)
    self.TxtMyself.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridMultiDimGradePlayer:SwitchDisabledLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(true)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridMultiDimGradePlayer:SwitchAlreadyLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridMultiDimGradePlayer:AddLikeNumber()
    self.LikeCount = self.LikeCount + 1
    self.TxtPraise.gameObject:SetActiveEx(self.LikeCount ~= 0)
    self.TxtPraise.text = CSXTextManagerGetText("MultiDimAddLike", self.LikeCount)
end

return XUiGridMultiDimGradePlayer