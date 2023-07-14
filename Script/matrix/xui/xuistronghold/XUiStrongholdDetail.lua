local XUiGridStrongholdBuff = require("XUi/XUiStronghold/XUiGridStrongholdBuff")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiStrongholdDetail = XLuaUiManager.Register(XLuaUi, "UiStrongholdDetail")

function XUiStrongholdDetail:OnAwake()
    self:AutoAddListener()

    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridBossBuff.gameObject:SetActiveEx(false)
    self.GridBaseBuff.gameObject:SetActiveEx(false)
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
end

function XUiStrongholdDetail:OnStart(groupId, closeCb, skipCb)
    self.CloseCb = closeCb
    self.SkipCb = skipCb
    self.RewardGrids = {}
    self.BossBuffGrids = {}
    self.BaseBuffGrids = {}

    self:UpdateData(groupId)
end

function XUiStrongholdDetail:UpdateData(groupId)
    self.GroupId = groupId
    XDataCenter.StrongholdManager.SetCurrentSelectGroupId(groupId)
end

function XUiStrongholdDetail:OnEnable()
    self:UpdateView()
    self:UpdateEndurance()
    self:UpdateSupport()
end

function XUiStrongholdDetail:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE,
        XEventId.EVENT_STRONGHOLD_TEAMLIST_CHANGE,
    }
end

function XUiStrongholdDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        self:UpdateView()
    elseif evt == XEventId.EVENT_STRONGHOLD_ENDURANCE_CHANGE then
        self:UpdateEndurance()
    elseif evt == XEventId.EVENT_STRONGHOLD_TEAMLIST_CHANGE then
        self:UpdateSupport()
    end
end

function XUiStrongholdDetail:UpdateView()
    local groupId = self.GroupId

    --只有首通奖励
    local firstDrop = not XDataCenter.StrongholdManager.IsGroupFinished(groupId)
    if firstDrop then
        local rewardId = XDataCenter.StrongholdManager.GetGroupRewardId(groupId)
        local oRewards = XRewardManager.GetRewardList(rewardId)
        local rewards = oRewards and XTool.Clone(oRewards) or {}

        --增加电能
        local addElectric = XStrongholdConfigs.GetGroupAddElectricEnergy(groupId)
        if addElectric > 0 then
            table.insert(rewards, XRewardManager.CreateRewardGoods(XDataCenter.StrongholdManager.GetBatteryItemId(), addElectric))
        end

        for index, item in ipairs(rewards) do
            local grid = self.RewardGrids[index]

            if not grid then
                local ui = index == 1 and self.GridCommon or CSUnityEngineObjectInstantiate(self.GridCommon, self.PanelDropContent)
                grid = XUiGridCommon.New(self, ui)
                self.RewardGrids[index] = grid
            end

            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end

        for index = #rewards + 1, #self.RewardGrids do
            self.RewardGrids[index].GameObject:SetActiveEx(false)
        end
    end
    self.PanelDrop.gameObject:SetActiveEx(firstDrop)

    --据点描述
    local detailBg = XStrongholdConfigs.GetGroupDetailBg(groupId)
    local showBg = not string.IsNilOrEmpty(detailBg)
    if showBg then
        self.RImgTitleBg:SetRawImage(detailBg)
        self.TxtTitleWithBg.text = XStrongholdConfigs.GetGroupName(groupId)
        self.TxtTipWithBg.text = XStrongholdConfigs.GetGroupDetailDesc(groupId)
    else
        self.TxtTitle.text = XStrongholdConfigs.GetGroupName(groupId)
        self.TxtTip.text = XStrongholdConfigs.GetGroupDetailDesc(groupId)
    end
    self.TxtTip.gameObject:SetActiveEx(not showBg)
    self.TxtTitle.gameObject:SetActiveEx(not showBg)
    self.TxtTipWithBg.gameObject:SetActiveEx(showBg)
    self.TxtTitleWithBg.gameObject:SetActiveEx(showBg)
    self.RImgTitleBg.gameObject:SetActiveEx(showBg)

    local teamNum = XDataCenter.StrongholdManager.GetGroupRequireTeamNum(groupId)
    self.TxtRequrireTeamNum.text = teamNum

    --据点BossBuff
    local bossBuffIds = XDataCenter.StrongholdManager.GetGroupBossBuffIds(groupId)
    local showBossBuff = #bossBuffIds > 0
    self.TxtBossBuff.gameObject:SetActiveEx(showBossBuff)
    self.PanelBossBuff.gameObject:SetActiveEx(showBossBuff)

    local isBossBuff = true
    for index, buffId in ipairs(bossBuffIds) do
        local grid = self.BossBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBossBuff or CSUnityEngineObjectInstantiate(self.GridBossBuff, self.PanelBossBuff)
            grid = XUiGridStrongholdBuff.New(go, nil, self.SkipCb)
            self.BossBuffGrids[index] = grid
        end

        grid:Refresh(buffId, isBossBuff)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #bossBuffIds + 1, #self.BossBuffGrids do
        local grid = self.BossBuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    --据点BaseBuff
    local baseBuffIds = XDataCenter.StrongholdManager.GetGroupBaseBuffIds(groupId)
    local showBaseBuff = #baseBuffIds > 0
    self.TxtBaseBuff.gameObject:SetActiveEx(showBaseBuff)
    self.PanelBaseBuff.gameObject:SetActiveEx(showBaseBuff)

    local isBossBuff = false
    for index, buffId in ipairs(baseBuffIds) do
        local grid = self.BaseBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBaseBuff or CSUnityEngineObjectInstantiate(self.GridBaseBuff, self.PanelBaseBuff)
            grid = XUiGridStrongholdBuff.New(go, nil, self.SkipCb)
            self.BaseBuffGrids[index] = grid
        end

        grid:Refresh(buffId, isBossBuff)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #baseBuffIds + 1, #self.BaseBuffGrids do
        local grid = self.BaseBuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

end

function XUiStrongholdDetail:UpdateEndurance()
    local groupId = self.GroupId
    local costEndurance = XDataCenter.StrongholdManager.GetGroupCostEndurance(groupId)
    local curEndurance = XDataCenter.StrongholdManager.GetCurEndurance()
    self.TxtEndurance.text = costEndurance .. "/" .. curEndurance
end

function XUiStrongholdDetail:UpdateSupport()
    local groupId = self.GroupId
    local isActive = XDataCenter.StrongholdManager.CheckGroupSupportAcitve(groupId)
    self.BtnAssitantBuff:SetDisable(not isActive)
end

function XUiStrongholdDetail:AutoAddListener()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnEnter.CallBack = function() self:OnClickBtnEnter() end
    self.BtnAssitantBuff.CallBack = function() self:OnClickBtnAssitantBuff() end
end

function XUiStrongholdDetail:OnClickBtnClose()
    self:Close()
    if self.CloseCb then self.CloseCb() end
end

function XUiStrongholdDetail:OnClickBtnEnter()
    local groupId = self.GroupId

    local btnFunc = function()
        self:Close()
        if self.CloseCb then self.CloseCb() end
        XLuaUiManager.Open("UiStrongholdDeploy", groupId)
    end

    --有关卡进度的时候：作战开始/主界面会保存当前对其他梯队的修改，返回会触发撤退的二次确认弹窗
    local fightingGroupId = XDataCenter.StrongholdManager.CheckAnyGroupHasFinishedStage()
    if XTool.IsNumberValid(fightingGroupId)
    and not XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(groupId)
    then
        local title = CSXTextManagerGetText("StrongholdTeamRestartConfirmTitle")
        local content = CSXTextManagerGetText("StrongholdTeamRestartConfirmContentOther", XStrongholdConfigs.GetGroupName(fightingGroupId))
        local callFunc = function()
            XDataCenter.StrongholdManager.ResetStrongholdGroupRequest(fightingGroupId, btnFunc)
        end
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        btnFunc()
    end
end

function XUiStrongholdDetail:OnClickBtnAssitantBuff()
    local groupId = self.GroupId
    XDataCenter.StrongholdManager.OpenUiSupport(groupId)
end