local XUiPanelBossStgae = XClass(nil, "XUiPanelBossStgae")
local BOSS_MAX_COUNT = 3

function XUiPanelBossStgae:Ctor(parent, ui, bossList)
    self.Parent = parent
    self.BossList = bossList
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Init()
end

function XUiPanelBossStgae:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelBossStgae:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelBossStgae:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelBossStgae:AutoAddListener()
    self:RegisterClickEvent(self.BtnEnter1, self.OnBtnEnter1Click)
    self:RegisterClickEvent(self.BtnEnter2, self.OnBtnEnter2Click)
    self:RegisterClickEvent(self.BtnEnter3, self.OnBtnEnter3Click)
    self:RegisterClickEvent(self.BtnName1, self.OnBtnName1Click)
    self:RegisterClickEvent(self.BtnName2, self.OnBtnName2Click)
    self:RegisterClickEvent(self.BtnName3, self.OnBtnName3Click)
end

function XUiPanelBossStgae:Init()
    self:RefreshBossInfo()
end

function XUiPanelBossStgae:RefreshBossInfo()
    self.GroupId = {}
    for i = 1, BOSS_MAX_COUNT do
        if not self.BossList[i] then
            self["PanelStageLock" .. i].gameObject:SetActiveEx(true)
            self["PanelStageOpen" .. i].gameObject:SetActiveEx(false)
            self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(false)
            self["PanelHideBoss" .. i].gameObject:SetActiveEx(false)
            self["PanelBossLeftTime" .. i].gameObject:SetActiveEx(false)
            self["TxtBoosName" .. i].gameObject:SetActiveEx(false)
            self["PanelRongtiaoBuff" .. i].gameObject:SetActiveEx(false)
            self["TxtBoosName" .. i].text = "--"
            self["TxtBoosLevel" .. i].text = "--"
            return
        end

        local bossId = self.BossList[i]
        self["PanelStageLock" .. i].gameObject:SetActiveEx(false)
        self["PanelStageOpen" .. i].gameObject:SetActiveEx(true)
        self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(true)

        local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(bossId, i)
        if bossInfo.isHideBoss then
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameHideDesc", bossInfo.bossDiffiName)
        else
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameNotHideDesc", bossInfo.bossDiffiName)
        end

        self["TxtBoosName" .. i].text = bossInfo.bossName
        self["RImgBossIcon" .. i]:SetRawImage(bossInfo.bossIcon)
        self["PanelHideBoss" .. i].gameObject:SetActiveEx(bossInfo.isHideBoss)

        self["ImgTag" .. i].gameObject:SetActiveEx(bossInfo.tagIcon ~= nil)
        if bossInfo.tagIcon then
            self.Parent:SetUiSprite(self["ImgTag" .. i], bossInfo.tagIcon)
        end

        if bossInfo.groupName then
            self["BtnName" .. i]:SetName(bossInfo.groupName)
        end

        if bossInfo.groupIcon then
            self["BtnName" .. i]:SetSprite(bossInfo.groupIcon)
        end

        local leftTime = XFubenBossSingleConfigs.GetBossSectionLeftTime(bossId)
        if leftTime > 0 then
            local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            self["TxtBossLeftTime" .. i].text = CS.XTextManager.GetText("BossSingleBossSectionLeftTime", timeStr)
            self["PanelBossLeftTime" .. i].gameObject:SetActiveEx(true)
        else
            self["PanelBossLeftTime" .. i].gameObject:SetActiveEx(false)
        end

        local teamBuffId = XFubenBossSingleConfigs.GetBossSectionTeamBuffId(bossId)
        local showBuffIcon = teamBuffId > 0
        self["PanelRongtiaoBuff" .. i].gameObject:SetActiveEx(showBuffIcon)

        self.GroupId[i] = bossInfo.groupId
    end
end

function XUiPanelBossStgae:RefreshBossDifficult()
    for i = 1, BOSS_MAX_COUNT do
        if self.BossList[i] then
            local bossId = self.BossList[i] or 0
            local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(bossId, i)
            self["TxtBoosName" .. i].text = bossInfo.bossName
            self["RImgBossIcon" .. i]:SetRawImage(bossInfo.bossIcon)
            self["PanelHideBoss" .. i].gameObject:SetActiveEx(bossInfo.isHideBoss)

            if bossInfo.isHideBoss then
                self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameHideDesc", bossInfo.bossDiffiName)
            else
                self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameNotHideDesc", bossInfo.bossDiffiName)
            end
        else
            self["TxtBoosName" .. i].text = "--"
            self["TxtBoosLevel" .. i].text = "--"
            self["PanelHideBoss" .. i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelBossStgae:EnterDetail(index)
    if not self.BossList[index] then
        XUiManager.TipText("BossSingleBossNotEnough")
        return
    end
    self.Parent:ShowBossDetail(self.BossList[index])
end

function XUiPanelBossStgae:PanelBossContentActive(active)
    self.GameObject:SetActiveEx(active)
    self:RefreshBossInfo()
end

function XUiPanelBossStgae:OnBtnEnter1Click()
    self:EnterDetail(1)
end

function XUiPanelBossStgae:OnBtnEnter2Click()
    self:EnterDetail(2)
end

function XUiPanelBossStgae:OnBtnEnter3Click()
    self:EnterDetail(3)
end

function XUiPanelBossStgae:OnBtnName1Click()
    local groupId = self.GroupId[1]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStgae:OnBtnName2Click()
    local groupId = self.GroupId[2]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStgae:OnBtnName3Click()
    local groupId = self.GroupId[3]
    self.Parent:ShowBossGroupInfo(groupId)
end

return XUiPanelBossStgae