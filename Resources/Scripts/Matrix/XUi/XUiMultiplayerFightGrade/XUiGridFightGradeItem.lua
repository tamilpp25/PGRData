local XUiGridFightGradeItem = XClass(nil, "XUiGridFightGradeItem")
local XUiGridFightDataItem = require("XUi/XUiMultiplayerFightGrade/XUiGridFightDataItem")

function XUiGridFightGradeItem:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAddFriend, self.OnBtnAddFriendClick)
end

function XUiGridFightGradeItem:OnBtnReportClick()
    if self.IsAlreadyReport then
        return
    end
    XUiManager.TipText("ReportFinish")
    self.BtnReport.ButtonState = CS.UiButtonState.Disable
    self.IsAlreadyReport = true
end

function XUiGridFightGradeItem:OnBtnLikeClick()
    self.Parent:OnAddLike(self.PlayerData.Id)
end

function XUiGridFightGradeItem:OnBtnAddFriendClick()
    self.Parent:OnApplyFriend(self.PlayerData.Id)
end

function XUiGridFightGradeItem:Init(playerData, playerCount)
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
    local headIcon = XDataCenter.CharacterManager.GetCharSmallHeadIconByCharacter(playerData.Character)
    self.RImgIcon:SetRawImage(headIcon)
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(playerData.Id, playerData.Name)
    local isArenaOnline = playerData.StageType and playerData.StageType == XDataCenter.FubenManager.StageType.ArenaOnline
    local isPass = playerData.HaveFirstPass and playerCount > 1
    self.PanelArenaOnline.gameObject:SetActiveEx(isArenaOnline and isPass)

    local item1 = CS.UnityEngine.GameObject.Instantiate(self.GridFightDataItem, self.PanelFightDataContainer)
    local item2 = CS.UnityEngine.GameObject.Instantiate(self.GridFightDataItem, self.PanelFightDataContainer)
    --TODO 配置名字
    self.GridFightDataList = {
        XUiGridFightDataItem.New(self.GridFightDataItem, CS.XTextManager.GetText("FightGradeOutput")),
        XUiGridFightDataItem.New(item1, CS.XTextManager.GetText("FightGradeCure")),
        XUiGridFightDataItem.New(item2, CS.XTextManager.GetText("FightGradeBreak")),
    }
end

function XUiGridFightGradeItem:Refresh(dpsData)
    if dpsData then
        self.GridFightDataList[1]:Refresh(dpsData.IsDamageTotalMvp, dpsData.DamageTotal)
        self.GridFightDataList[2]:Refresh(dpsData.IsCureMvp, dpsData.Cure)
        self.GridFightDataList[3]:Refresh(dpsData.IsBreakEndureMvp, dpsData.BreakEndure)
    else
        self.GridFightDataList[1]:Refresh(false, 0)
        self.GridFightDataList[2]:Refresh(false, 0)
        self.GridFightDataList[3]:Refresh(false, 0)
    end
end

function XUiGridFightGradeItem:SwitchNormal()
    self.PanelOperation.gameObject:SetActiveEx(true)
    self.TxtMyself.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(true)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridFightGradeItem:SwitchMyself()
    self.PanelOperation.gameObject:SetActiveEx(false)
    self.TxtMyself.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
end

function XUiGridFightGradeItem:SwitchDisabledLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(true)
    self.ImgLikeAlready.gameObject:SetActiveEx(false)
    self.BtnLike.gameObject:SetActiveEx(false)
end

function XUiGridFightGradeItem:SwitchAlreadyLike()
    self.ImgLikeDisabled.gameObject:SetActiveEx(false)
    self.ImgLikeAlready.gameObject:SetActiveEx(true)
    self.BtnLike.gameObject:SetActiveEx(false)
end

return XUiGridFightGradeItem