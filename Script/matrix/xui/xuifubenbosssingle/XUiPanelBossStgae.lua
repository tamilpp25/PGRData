---@class XUiPanelBossStgae : XUiNode
local XUiPanelBossStgae = XClass(XUiNode, "XUiPanelBossStgae")
local BOSS_MAX_COUNT = 3

function XUiPanelBossStgae:OnStart(bossList)
    self._BossList = bossList
    self._GroupId = {}
    self:_RegisterButtonListeners()
    self:_RefreshBossInfo()
end

function XUiPanelBossStgae:OnEnable()
    self:_RefreshBossInfo()
end

function XUiPanelBossStgae:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter1, self.OnBtnEnter1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter2, self.OnBtnEnter2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter3, self.OnBtnEnter3Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName1, self.OnBtnName1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName2, self.OnBtnName2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName3, self.OnBtnName3Click, true)
end

function XUiPanelBossStgae:_RefreshBossInfo()
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

        local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(bossId, i)
        local curScore = XDataCenter.FubenBossSingleManager.GetBossCurScore(bossId)
        if bossInfo.isHideBoss then
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevelHideBoss", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameHideDesc", bossInfo.bossDiffiName)
        else
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevel", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameNotHideDesc", bossInfo.bossDiffiName)
        end

        self["TxtBoosName" .. i].text = bossInfo.bossName
        self["RImgBossIcon" .. i]:SetRawImage(bossInfo.bossIcon)

        if bossInfo.groupName then
            self["BtnName" .. i]:SetName(bossInfo.groupName)
        end

        if bossInfo.groupIcon then
            self["BtnName" .. i]:SetSprite(bossInfo.groupIcon)
        end

        self._GroupId[i] = bossInfo.groupId
    end
end

function XUiPanelBossStgae:_EnterDetail(index)
    if not self._BossList[index] then
        XUiManager.TipText("BossSingleBossNotEnough")
        return
    end

    self.Parent:ShowBossDetail(self._BossList[index])
end

function XUiPanelBossStgae:OnBtnEnter1Click()
    self:_EnterDetail(1)
end

function XUiPanelBossStgae:OnBtnEnter2Click()
    self:_EnterDetail(2)
end

function XUiPanelBossStgae:OnBtnEnter3Click()
    self:_EnterDetail(3)
end

function XUiPanelBossStgae:OnBtnName1Click()
    local groupId = self._GroupId[1]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStgae:OnBtnName2Click()
    local groupId = self._GroupId[2]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStgae:OnBtnName3Click()
    local groupId = self._GroupId[3]
    self.Parent:ShowBossGroupInfo(groupId)
end

return XUiPanelBossStgae