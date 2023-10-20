local XUiGridStrongHoldTeamMember = require("XUi/XUiStronghold/XUiGridStrongHoldTeamMember")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local LongClickIntervel = 100
local AddCountPerPressTime = 1 / 150

---@class XUiGridStrongholdTeam
local XUiGridStrongholdTeam = XClass(nil, "XUiGridStrongholdTeam")

function XUiGridStrongholdTeam:Ctor(ui, fightCb, checkCountCb, countChangeCb, getMaxCountCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGrids = {}
    self.FightCb = fightCb
    self.CheckCountCb = checkCountCb
    self.CountChangeCb = countChangeCb
    self.GetMaxCountCb = getMaxCountCb
    self.Count = 0

    XTool.InitUiObject(self)

    self.BtnRune.CallBack = function()
        self:OnBtnRuneClick()
    end
    self.BtnFight.CallBack = function()
        self:OnBtnFightClick()
    end
    self.BtnReset.CallBack = function()
        self:OnBtnResetClick()
    end
    XUiHelper.RegisterClickEvent(self, self.BtnAddSelect, self.OnClickAdd)
    XUiHelper.RegisterClickEvent(self, self.BtnMinusSelect, self.OnClickReduce)
    XUiButtonLongClick.New(self.BtnAddSelect, LongClickIntervel, self, nil, self.OnLongClickBtnAdd, nil, true)
    XUiButtonLongClick.New(self.BtnMinusSelect, LongClickIntervel, self, nil, self.OnLongClickBtnReduce, nil, true)

    self.GridDeployMember.gameObject:SetActiveEx(false)
    self.RImgTool1:SetRawImage(XStrongholdConfigs.GetElectricIcon())

    XEventManager.AddEventListener(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK, self.UpdateView, self)
end

function XUiGridStrongholdTeam:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK, self.UpdateView, self)
end

function XUiGridStrongholdTeam:InitElectric(count)
    self.Count = count
end

function XUiGridStrongholdTeam:Refresh(teamList, teamId, groupId, isPrefab)
    ---@type XStrongholdTeam[]
    self.TeamList = teamList
    --队伍数据更改赋值
    self.TeamListClip = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId, teamList)
    --仅显示用
    self.TeamId = teamId
    self.GroupId = groupId
    local team = self:GetTeam()
    self.Plugin = team:GetPlugin(XEnumConst.StrongHold.AttrPluginId)
    self.IsTeamEmpty = team:GetInTeamMemberCount() == 0

    if team:IsRune() then
        local runeDesc = team:GetRuneDesc()
        self.TxtTitle.text = team:GetRuneName()
        self.TxtBuff.text = runeDesc
        self.TxtNone.gameObject:SetActiveEx(false)
    else
        self.TxtTitle.text = ""
        self.TxtBuff.text = ""
        self.TxtNone.gameObject:SetActiveEx(true)
    end

    if isPrefab then
        --队伍预设
        self.TxtTeamTitle.text = ""
        self.TxtTeamBuffDetail.text = ""
        self.TxtTeamName.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)
        self.PanelVictory.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
    else
        --战斗编队
        local stageIndex = teamId
        local isFinished = XDataCenter.StrongholdManager.IsGroupStageFinished(groupId, stageIndex)
        self.TxtTeamTitle.text = XDataCenter.StrongholdManager.GetGroupStageName(groupId, teamId)
        local buffDesc = XDataCenter.StrongholdManager.GetGroupStageBuffDesc(groupId, teamId)
        local extendBuffDesc = XDataCenter.StrongholdManager.GetGroupStageExtendBuffDesc(groupId, teamId)
        if extendBuffDesc == "" then
            self.TxtTeamBuffDetail.text = buffDesc
        else
            self.TxtTeamBuffDetail.text = string.format("%s%s", buffDesc, extendBuffDesc)
        end
        self.TxtTeamName.text = ""
        self.PanelVictory.gameObject:SetActiveEx(isFinished)
        self.BtnFight.gameObject:SetActiveEx(true)
        self.BtnFight:SetButtonState(self.IsTeamEmpty and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end

    local hasRune = team:HasRune()
    self.PanelNor.gameObject:SetActiveEx(hasRune)
    self.PanelEmpty.gameObject:SetActiveEx(not hasRune)
    if hasRune then
        local runeId, subRuneId = team:GetRune()
        self.ImgRune:SetSprite(XStrongholdConfigs.GetRuneIcon(runeId))
        self.ImgSubRune:SetSprite(XStrongholdConfigs.GetSubRuneIcon(subRuneId))
        self.ImgColor.color = team:GetRuneColor()
    end

    local doNotShowEffect = true
    self:UpdateView(doNotShowEffect)
end

function XUiGridStrongholdTeam:UpdateView(doNotShowEffect)
    self:UpdateTeam()
    self:UpdateCount()
end

function XUiGridStrongholdTeam:UpdateTeam()
    local groupId = self.GroupId
    local teamId = self.TeamId
    local teamList = self.TeamList

    local requireMemberNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    if not XTool.IsNumberValid(requireMemberNum) then
        XLog.Error(
            string.format(
                "关卡要求上阵人数为0空，请检查配置，groupId:%d，teamId:%d，配置路径：%s",
                groupId,
                teamId,
                XStrongholdConfigs.GetGroupConfigPath()
            )
        )
        return
    end

    for index = 1, requireMemberNum do
        local grid = self.MemberGrids[index]
        if not grid then
            local go =
                index == 1 and self.GridDeployMember or
                CSUnityEngineObjectInstantiate(self.GridDeployMember, self.PanelDeployMembers)
            grid = XUiGridStrongHoldTeamMember.New(go)
            self.MemberGrids[index] = grid
        end

        grid:Refresh(teamList, teamId, index, groupId)

        --蓝色放到第一位
        if index == 2 then
            grid.Transform:SetAsFirstSibling()
        end

        grid.GameObject:SetActiveEx(true)
    end

    for index = requireMemberNum + 1, #self.MemberGrids do
        self.MemberGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridStrongholdTeam:OnClickPlugin()
    XLuaUiManager.Open("UiStrongholdCoreTips", self.TeamList, self.TeamId, self.GroupId)
end

function XUiGridStrongholdTeam:GetTeam(isUseClip)
    -- isUseClip时仅显示队伍数据用
    return isUseClip and self.TeamListClip[self.TeamId] or self.TeamList[self.TeamId]
end

function XUiGridStrongholdTeam:OnBtnRuneClick()
    local runeIdList = XDataCenter.StrongholdManager.GetAllRuneIds()
    if XTool.IsTableEmpty(runeIdList) then
        XLog.Error("XUiStrongholdRune:InitTabBtnGroup error, 服务器下发可用符文列表为空")
        return
    end
    local team = self:GetTeam()
    local runeId, subRuneId = team:GetRune()
    XLuaUiManager.Open("UiStrongholdRune", self.TeamList, self.TeamId, self.GroupId, runeId)
end

function XUiGridStrongholdTeam:OnBtnFightClick()
    if self.IsTeamEmpty then
        XUiManager.TipText("StrongholdTeamEmpty")
        return
    end
    if self.FightCb then
        self.FightCb()
    end
    XDataCenter.StrongholdManager.TryEnterFight(self.GroupId, self.TeamId, self.TeamList)
end

function XUiGridStrongholdTeam:OnBtnResetClick()
    local callFunc = function()
        local groupId = self.GroupId
        local stageId = XDataCenter.StrongholdManager.GetGroupStageId(groupId, self.TeamId)
        XDataCenter.StrongholdManager.ResetStrongholdStageRequest(groupId, stageId)
    end
    local title = CSXTextManagerGetText("StrongholdTeamResetStageConfirmTitle")
    local content = CSXTextManagerGetText("StrongholdTeamResetStageConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiGridStrongholdTeam:OnClickAdd()
    self:AddCount(1)
end

function XUiGridStrongholdTeam:OnLongClickBtnAdd(pressingTime)
    local maxCount = self.GetMaxCountCb(self.Plugin:GetCostElectricSingle())
    local addCount = XMath.Clamp(math.floor(pressingTime * AddCountPerPressTime), 1, maxCount)
    local countLimitLeft = self.Plugin:GetCountLimit() - self.Count
    if countLimitLeft < 1 then
        countLimitLeft = 1
    end
    addCount = XMath.Clamp(addCount, 1, countLimitLeft)

    if addCount > 0 then
        self:AddCount(addCount)
    else
        XUiManager.TipText("StrongholdPluginAddFail")
    end
end

function XUiGridStrongholdTeam:OnClickReduce()
    self:SubCount(1)
end

function XUiGridStrongholdTeam:OnLongClickBtnReduce(pressingTime)
    local subCount = XMath.Clamp(math.floor(pressingTime * AddCountPerPressTime), 0, self.Count)
    self:SubCount(subCount)
end

function XUiGridStrongholdTeam:AddCount(addCount)
    local costElectric = self.Plugin:GetCostElectricSingle() * addCount
    if not self.CheckCountCb(costElectric) then
        XUiManager.TipText("StrongholdPluginAddFail")
        return
    end

    local newCount = self.Count + addCount
    local countLimit = self.Plugin:GetCountLimit()
    if newCount > countLimit then
        XUiManager.TipText("StrongholdPluginAddOverLimit")
        return
    end

    self.Count = newCount
    self.CountChangeCb(costElectric)
    self:UpdateCount()
end

function XUiGridStrongholdTeam:SubCount(subCount)
    local newCount = self.Count - subCount
    if newCount < 0 then
        return
    end

    local costElectric = self.Plugin:GetCostElectricSingle() * subCount
    self.Count = newCount
    self.CountChangeCb(-costElectric)
    self:UpdateCount()
end

function XUiGridStrongholdTeam:UpdateCount()
    self.TxtNum.text = self.Count * XStrongholdConfigs.GetPluginUseElectric(XEnumConst.StrongHold.AttrPluginId)
    self.TxtBuffDetail.text = XUiHelper.GetText("StrongholdPluginAddAttr", self.Count * XStrongholdConfigs.GetPluginAddAbility(XEnumConst.StrongHold.AttrPluginId))
    self.TeamList[self.TeamId]:SetPlugin(XEnumConst.StrongHold.AttrPluginId, self.Count)
end

return XUiGridStrongholdTeam
