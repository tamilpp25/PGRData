local XUiPanelGroupInfo = XClass(nil, "XUiPanelGroupInfo")

function XUiPanelGroupInfo:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridBosList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Init()
end

function XUiPanelGroupInfo:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelGroupInfo:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelGroupInfo:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelGroupInfo:AutoAddListener()
    self:RegisterClickEvent(self.BtnBlock, self.OnBtnBlockClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnBlockClick)
end

function XUiPanelGroupInfo:Init()
    self.GridBoss.gameObject:SetActiveEx(false)
    -- v2.4 Boss刷新规则改变,策划需求不显示
    if not XTool.UObjIsNil(self.TxtInfo) then
        self.TxtInfo.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGroupInfo:ShowBossGroupInfo(groupId)
    self.RootUi:PlayAnimation("GroupInfoEnable")
    local groupInfo = XFubenBossSingleConfigs.GetBossSingleGroupById(groupId)
    self.TxtGroupName.text = groupInfo.GroupName

    for _, grid in pairs(self.GridBosList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #groupInfo.SectionId do
        local bossId = groupInfo.SectionId[i]
        local sectionCfg = XDataCenter.FubenBossSingleManager.GetBossSectionCfg(bossId)
        -- 判断关闭时间
        if XFubenBossSingleConfigs.IsInBossSectionTime(bossId) then
            local grid = self.GridBosList[i]
            if not grid then
                grid = CS.UnityEngine.Object.Instantiate(self.GridBoss)
                grid.transform:SetParent(self.PanelScoreContent, false)
                self.GridBosList[i] = grid
            end

            local headIcon = XUiHelper.TryGetComponent(grid.transform, "RImgBossIcon", "RawImage")
            local nickname = XUiHelper.TryGetComponent(grid.transform, "TxtBoosName", "Text")
            local sossStageCfg = XDataCenter.FubenBossSingleManager.GetBossStageCfg(sectionCfg.StageId[1])
            headIcon:SetRawImage(sectionCfg.BossHeadIcon)
            nickname.text = sossStageCfg.BossName

            local panelBossLeftTime = XUiHelper.TryGetComponent(grid.transform, "PanelBossLeftTime")
            local leftTime = XFubenBossSingleConfigs.GetBossSectionLeftTime(bossId)
            if leftTime > 0 then
                local textleftTime = XUiHelper.TryGetComponent(grid.transform, "PanelBossLeftTime/TxtBossLeftTime", "Text")
                local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                textleftTime.text = CS.XTextManager.GetText("BossSingleBossSectionLeftTime", timeStr)
                panelBossLeftTime.gameObject:SetActiveEx(true)
            else
                panelBossLeftTime.gameObject:SetActiveEx(false)
            end

            grid.gameObject:SetActiveEx(true)
        end
    end

    self.GameObject:SetActiveEx(true)
end

function XUiPanelGroupInfo:OnBtnBlockClick()
    self:HidePanel()
end

function XUiPanelGroupInfo:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelGroupInfo