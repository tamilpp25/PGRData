local XUiPanelResource = XClass(nil, "XUiPanelResource")
local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

function XUiPanelResource:Ctor(ui,parent)
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.Node = nil
    self.Parent = parent
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
    self._UiEvent = {}
end

function XUiPanelResource:SetData(node)
    self.Node = node
    self.TxtName.text = node:GetName()
    self.BtnPlayer:SetNameByGroup(1, node:GetMemberCount())
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())
    self.TxtHP.text = node:GetPercentageHP()
    self.PrograssHP.fillAmount = node:GetHP() / node:GetMaxHP()
    local buffData = node:GetFightEventDetailConfig()
    if buffData == nil then return end
    -- self.RImgBuffIcon:SetRawImage(buffData.Icon)
    self.TxtBuffName.text = buffData.Name
    self.TxtBuffDetails.text = buffData.Description
    self.PanelBuf.gameObject:SetActiveEx(false)
    --显示驻守占比
    if not XTool.IsNumberValid(self.Node._Id) then
        return
    end
    self.TxtProportion.text = XUiHelper.FormatText(XGuildWarConfig.GetClientConfigValues('DefendPercentDetail')[1],math.floor(XDataCenter.GuildWarManager.GetDefensePlayerPercentById(self.Node._Id)*100))
    
    self._IsRebuild = XDataCenter.GuildWarManager.IsDefensePointRebuilding(self.Node._Id)
    
    self.TxtRebuildTime.gameObject:SetActiveEx(self._IsRebuild)

    if self._IsRebuild then
        --不方便对单个界面进行XUiNode继承改造，因此生命周期还是先依赖父类
        self:RefreshRebuildTime()
        local timeId = XScheduleManager.ScheduleForever(handler(self,self.RefreshRebuildTime),XScheduleManager.SECOND,0)
        table.insert(self.Parent._TimerIds,timeId)
    end
    
    self:SetBuff()
end

function XUiPanelResource:SetBuff()
    local eventDetails = self.Node:GetAllFightEventDetailConfig()

    for i = 1, #eventDetails do
        local uiEvent = self._UiEvent[i]
        if not uiEvent then
            local ui = XUiHelper.Instantiate(self.PanelBuf.gameObject, self.PanelBuf.transform.parent.transform)
            uiEvent = XUiGuildWarStageDetailEvent.New(ui,self)
            self._UiEvent[i] = uiEvent
        end
        local event = eventDetails[i]
        uiEvent:Update(event)
        uiEvent.GameObject:SetActiveEx(true)
        uiEvent.PanelRebuild.gameObject:SetActiveEx(self._IsRebuild and not table.contains(XGuildWarConfig.GetClientConfigValues('BuffUnshowRebuilTagEvents'),tostring(event.Id)))

    end
    for i = #eventDetails + 1, #self._UiEvent do
        local uiEvent = self._UiEvent[i]
        uiEvent.GameObject:SetActiveEx(false)
    end
end

function XUiPanelResource:OnBtnHelpClicked()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end

function XUiPanelResource:OnBtnPlayerClicked()
    self.GuildWarManager.RequestRanking(XGuildWarConfig.RankingType.DefenseMembers, self.Node._Id
    , function(rankList, myRankInfo)
                XLuaUiManager.Open("UiGuildWarDefendRank", rankList, myRankInfo, XGuildWarConfig.RankingType.NodeStay, self.Node:GetUID(), self.Node)
            end)
end

function XUiPanelResource:RefreshRebuildTime()
    local nextTime = XDataCenter.GuildWarManager.GetNextAttackedTime()
    local leftTime = nextTime - XTime.GetServerNowTimestamp()
    self.TxtRebuildTime.text = XUiHelper.GetText('GuildWarRebuildTimeTip',XUiHelper.GetTime(leftTime,XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
end

function XUiPanelResource:AddTimer(cb)
    local timeId = XScheduleManager.ScheduleForever(cb,XScheduleManager.SECOND,0)
    table.insert(self.Parent._TimerIds,timeId)
end

return XUiPanelResource
