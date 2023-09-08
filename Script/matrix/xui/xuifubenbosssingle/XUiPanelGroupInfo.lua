---@class XUiPanelGroupInfo : XUiNode
local XUiPanelGroupInfo = XClass(XUiNode, "XUiPanelGroupInfo")

function XUiPanelGroupInfo:OnStart(rootUi)
    self._RootUi = rootUi
    self._GridBossList = {}
    self:_RegisterButtonListeners()
    self:_Init()
end

function XUiPanelGroupInfo:OnEnable()
    self:_Refresh()
end

function XUiPanelGroupInfo:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnBlock, self.Close, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close, true)
end

function XUiPanelGroupInfo:_Init()
    self.GridBoss.gameObject:SetActiveEx(false)
    -- v2.4 Boss刷新规则改变,策划需求不显示
    if not XTool.UObjIsNil(self.TxtInfo) then
        self.TxtInfo.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGroupInfo:_Refresh()
    if not self._GroupId then
        return
    end

    local groupInfo = XFubenBossSingleConfigs.GetBossSingleGroupById(self._GroupId)
    
    self._RootUi:PlayAnimation("GroupInfoEnable")
    self.TxtGroupName.text = groupInfo.GroupName

    for _, grid in pairs(self._GridBossList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #groupInfo.SectionId do
        local bossId = groupInfo.SectionId[i]
        local sectionCfg = XDataCenter.FubenBossSingleManager.GetBossSectionCfg(bossId)
        -- 判断关闭时间
        if XFubenBossSingleConfigs.IsInBossSectionTime(bossId) then
            local grid = self._GridBossList[i]
            if not grid then
                grid = CS.UnityEngine.Object.Instantiate(self.GridBoss)
                grid.transform:SetParent(self.PanelScoreContent, false)
                self._GridBossList[i] = grid
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
end

function XUiPanelGroupInfo:SetGroupId(groupId)
    self._GroupId = groupId
end

return XUiPanelGroupInfo