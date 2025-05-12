---@class XUiPanelBossStage : XUiNode
---@field _Control XFubenBossSingleControl
local XUiPanelBossStage = XClass(XUiNode, "XUiPanelBossStage")
local BOSS_MAX_COUNT = 3

function XUiPanelBossStage:OnStart(bossList)
    self._BossList = bossList
    self._GroupId = {}
    self:_RegisterButtonListeners()
end

function XUiPanelBossStage:OnEnable()
    self:_Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
end

function XUiPanelBossStage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
end

function XUiPanelBossStage:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter1, self.OnBtnEnter1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter2, self.OnBtnEnter2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter3, self.OnBtnEnter3Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName1, self.OnBtnName1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName2, self.OnBtnName2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName3, self.OnBtnName3Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMode, self.OnBtnModeClick, true)
end

function XUiPanelBossStage:_RefreshBossInfo()
    self._GroupId = {}
    for i = 1, BOSS_MAX_COUNT do
        if not self._BossList[i] then
            self["PanelStageLock" .. i].gameObject:SetActiveEx(true)
            self["PanelStageOpen" .. i].gameObject:SetActiveEx(false)
            self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(false)
            self["TxtBoosName" .. i].gameObject:SetActiveEx(false)
            self["PanelLevel" .. i].gameObject:SetActiveEx(false)
            return
        end

        local bossId = self._BossList[i]
        self["PanelStageLock" .. i].gameObject:SetActiveEx(false)
        self["PanelStageOpen" .. i].gameObject:SetActiveEx(true)
        self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(true)
        self["TxtBoosName" .. i].gameObject:SetActiveEx(true)
        self["PanelLevel" .. i].gameObject:SetActiveEx(true)

        local bossInfo = self._Control:GetBossCurDifficultyInfo(bossId, i)
        local curScore = self._Control:GetBossCurScore(bossId)
        if bossInfo:GetIsHideBoss() then
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevelHideBoss", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameHideDesc", bossInfo:GetBossDifficultyName())
        else
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevel", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameNotHideDesc", bossInfo:GetBossDifficultyName())
        end

        self["TxtBoosName" .. i].text = bossInfo:GetBossName()
        self["RImgBossIcon" .. i]:SetRawImage(bossInfo:GetBossIcon())

        if bossInfo:GetGroupName() then
            self["BtnName" .. i]:SetName(bossInfo:GetGroupName())
        end

        if bossInfo:GetGroupIcon() then
            self["BtnName" .. i]:SetSprite(bossInfo:GetGroupIcon())
        end

        self._GroupId[i] = bossInfo:GetGroupId()
    end
end

function XUiPanelBossStage:_EnterDetail(index)
    if not self._BossList[index] then
        XUiManager.TipText("BossSingleBossNotEnough")
        return
    end

    self.Parent:ShowBossDetail(self._BossList[index])
end

function XUiPanelBossStage:_RefreshPanelMode()
    local bossSingle = self._Control:GetBossSingleData()
    local isOpen = self._Control:CheckChallengeOpen()
    local effect = self.BtnMode.transform:FindTransform("Effect")

    self.PanelMode.gameObject:SetActiveEx(bossSingle:IsNewVersion() and self._Control:IsInLevelTypeExtreme())
    self.BtnMode:SetDisable(not isOpen)
    self.TxtTips.text = XUiHelper.GetText("BossSingleModeTips")
    self.BtnMode:ShowReddot(isOpen and self._Control:CheckChallengeRedPoint())

    if effect then
        local isFirst = bossSingle:GetIsFirstUnlockChallenge()

        effect.gameObject:SetActiveEx(isOpen and isFirst)
        bossSingle:UnlockChallenge()
    end
end

function XUiPanelBossStage:_Refresh()
    self:_RefreshBossInfo()
    self:_RefreshPanelMode()
end

function XUiPanelBossStage:OnBtnEnter1Click()
    self:_EnterDetail(1)
end

function XUiPanelBossStage:OnBtnEnter2Click()
    self:_EnterDetail(2)
end

function XUiPanelBossStage:OnBtnEnter3Click()
    self:_EnterDetail(3)
end

function XUiPanelBossStage:OnBtnName1Click()
    local groupId = self._GroupId[1]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnName2Click()
    local groupId = self._GroupId[2]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnName3Click()
    local groupId = self._GroupId[3]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnModeClick()
    local isOpen = self._Control:CheckChallengeOpen()
    
    if isOpen then
        self._Control:OpenChallengeUi()
    else
        XUiManager.TipText("BossSingleModeTips")
    end
end

return XUiPanelBossStage