local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}
local MAX_ECHELON_MEMBER_COUNT = 3  --梯队最大成员数量
local XUiGridEchelonMember = require("XUi/XUiBfrt/TeamDeploy/XUiGridEchelonMember")
local XUiGridEchelonStageBuff = require("XUi/XUiBfrt/TeamDeploy/XUiGridEchelonStageBuff")
---@class XUiGridEchelon:XUiNode
---@field Parent XUiBfrtDeploy
local XUiGridEchelon = XClass(XUiNode, "XUiGridEchelon")

function XUiGridEchelon:OnStart(data)
    self:InitAutoScript()
    self:ResetEchelonInfo()
    self:UpdateEchelonInfo(data)
    self:AddBtnListener()
    self:AddOnStartEventListener()
end

function XUiGridEchelon:OnEnable()
    self:AddEventListener()
end

function XUiGridEchelon:OnDisable()
    self:RemoveEventListener()
end

function XUiGridEchelon:OnDestroy()
    self:RemoveOnDestroyListener()
end

--region Data - Team
function XUiGridEchelon:UpdateTeamInfo(team)
    self._EchelonData.TeamList[self._EchelonData.EchelonIndex] = team
    XEventManager.DispatchEvent(XEventId.EVENT_BFRT_TEAM_UPDATE)
end
--endregion

--region Ui - Init
-- auto
-- Automatic generation of code, forbid to edit
function XUiGridEchelon:InitAutoScript()
    self:AutoInitUi()
end

function XUiGridEchelon:AutoInitUi()
    self.PanelLeaderSkill = self.Transform:Find("PanelLeaderSkill")
    self.TxtLeaderSkill = self.Transform:Find("PanelLeaderSkill/TxtLeaderSkill"):GetComponent("Text")
    self.PanelRequire = self.Transform:Find("PanelRequire")
    self.TxtExtraCondition = self.Transform:Find("PanelRequire/TxtExtraCondition"):GetComponent("Text")
    self.PanelTitleBgLogistic = self.Transform:Find("PanelTitleBgLogistic")
    self.TxtTitleA = self.Transform:Find("PanelTitleBgLogistic/TxtTitle"):GetComponent("Text")
    self.PanelTitleBgFight = self.Transform:Find("PanelTitleBgFight")
    self.TxtTitle = self.Transform:Find("PanelTitleBgFight/TxtTitle"):GetComponent("Text")
    self.PanelEchelonMembers = self.Transform:Find("PanelEchelonMembers")
    self.GridEchelonMember = self.Transform:Find("PanelEchelonMembers/GridEchelonMember")
    self.TxtDoNotNeedFight = self.Transform:Find("TxtDoNotNeedFight"):GetComponent("Text")
    self.PanelLogisticSkill = self.Transform:Find("PanelLogisticSkill")
    self.TxtLogisticSkill = self.Transform:Find("PanelLogisticSkill/TxtLogisticSkill"):GetComponent("Text")
    self.ImgNotPassCondition = self.Transform:Find("ImgNotPassCondition"):GetComponent("Image")
end
--endregion

--region Ui - Echelon
function XUiGridEchelon:ResetEchelonInfo()
    ---@type XBfrtEchelonData
    self._EchelonData = nil
    ---@type XUiGridEchelonMember[]
    self.GirdEchelonMemberList = {}
    self.GridBuffList = {}  --关卡词缀对象列表

    self.GridEchelonMember.gameObject:SetActiveEx(false)
    self.TxtDoNotNeedFight.gameObject:SetActiveEx(false)
    self.PanelTitleBgFight.gameObject:SetActiveEx(false)
    self.PanelTitleBgLogistic.gameObject:SetActiveEx(false)
    self.PanelLogisticSkill.gameObject:SetActiveEx(false)
    self.PanelLeaderSkill.gameObject:SetActiveEx(false)
    self.TxtLeaderSkill.gameObject:SetActiveEx(false)
end

---@param data XBfrtEchelonData
function XUiGridEchelon:UpdateEchelonInfo(data)
    self._EchelonData = data
    
    self:_UpdateTitle()
    self:_UpdateTxtExtraCondition()
    self:_UpdateTxtLeaderSkill()
    self:_UpdatePanelEchelonMembers()
    self:_UpdateEchelonConditionState()
    self:_UpdateShowFightEventIds()
    self:_UpdatePass()
end

function XUiGridEchelon:UpdateNumberLeader()
    self:_UpdateTxtLeaderSkill()
    self:_UpdatePanelEchelonMembers()
    self:_UpdatePass()
end

function XUiGridEchelon:_RefreshEchelonByResetRecord(stageId)
    if not self._EchelonData or self._EchelonData.StageId ~= stageId then
        return
    end
    self:UpdateEchelonInfo(self._EchelonData)
end

function XUiGridEchelon:_OpenBattleRoomDetail(stageId, index)
    if not self._EchelonData or self._EchelonData.StageId ~= stageId then
        return
    end

    if index then -- 编队界面的索引和平面的不同 需要转换一下
        if index == 1 then
            index = 2
        elseif index == 2 then
            index = 1
        end
    end
    self.GirdEchelonMemberList[index]:OnOpenBattleRoleRoomDetail()
end

function XUiGridEchelon:_UpdateShowFightEventIds()
    local showFightEventIds = XDataCenter.BfrtManager.GetEchelonInfoShowFightEventIds(self._EchelonData.EchelonId)
    if XTool.IsTableEmpty(showFightEventIds) then
        self.PanelCore.gameObject:SetActiveEx(false)
        return
    end

    local gridBuff
    for i, eventId in ipairs(showFightEventIds) do
        gridBuff = self.GridBuffList[i]
        if not gridBuff then
            local grid = i == 1 and self.GridPlugin or CS.UnityEngine.Object.Instantiate(self.GridPlugin.gameObject, self.PanelCoreContent)
            gridBuff = XUiGridEchelonStageBuff.New(self, grid)
            self.GridBuffList[i] = gridBuff
        end
        gridBuff:Refresh(eventId, self._EchelonData.EchelonId)
        gridBuff.GameObject:SetActiveEx(true)
    end

    local showFightEventIdsCount = #showFightEventIds
    for i = showFightEventIdsCount + 1, #self.GridBuffList do
        self.GridBuffList[i].GameObject:SetActiveEx(false)
    end
    self.PanelCore.gameObject:SetActiveEx(true)
end

function XUiGridEchelon:_UpdateTitle()
    if self._EchelonData.EchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
        self.PanelTitleBgFight.gameObject:SetActive(true)
        self.TxtTitle.text = CS.XTextManager.GetText("BfrtFightEchelonTitle", self._EchelonData.EchelonIndex)
    elseif self._EchelonData.EchelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
        self.PanelTitleBgLogistic.gameObject:SetActive(true)
        self.TxtDoNotNeedFight.gameObject:SetActive(true)
        self.TxtTitleA.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitle", self._EchelonData.EchelonIndex)
    end
end

function XUiGridEchelon:_UpdateTxtExtraCondition()
    local hasCondition = self._EchelonData.ConditionId > 0
    self.TxtExtraCondition.gameObject:SetActive(hasCondition)

    if hasCondition then
        local template = XConditionManager.GetConditionTemplate(self._EchelonData.ConditionId)
        if template then
            self.TxtExtraCondition.text = template.Desc
        end
    end
end

function XUiGridEchelon:_UpdateTxtLeaderSkill()
    if self._EchelonData.EchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
        local team = self._EchelonData.TeamList[self._EchelonData.EchelonIndex]
        if team then
            local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(self._EchelonData.EchelonId, self._EchelonData.BfrtGroupId, self._EchelonData.EchelonIndex)
            local captainId = team[captainPos]
            if captainId and captainId > 0 then
                local captianSkillInfo = XMVCA.XCharacter:GetCaptainSkillInfoByCharId(captainId)
                self.TxtLeaderSkill.text = captianSkillInfo.Level > 0 and captianSkillInfo.Intro or string.format("%s%s", captianSkillInfo.Intro, CS.XTextManager.GetText("CaptainSkillLock"))
                self.TxtLeaderSkill.gameObject:SetActive(true)
            else
                self.TxtLeaderSkill.gameObject:SetActive(false)
            end
        else
            self.TxtLeaderSkill.gameObject:SetActive(false)
        end
        self.PanelLeaderSkill.gameObject:SetActive(true)
    else
        local logisticSkillDes = XDataCenter.BfrtManager.GetLogisticSkillDes(self._EchelonData.EchelonId)
        self.TxtLogisticSkill.text = logisticSkillDes
        self.PanelLogisticSkill.gameObject:SetActive(true)
    end
end

function XUiGridEchelon:_UpdatePanelEchelonMembers()
    ---@type XBfrtEchelonData
    self._EchelonData.MemberIndex = nil
    self._EchelonData.RequireAbility = nil

    for i = 1, MAX_ECHELON_MEMBER_COUNT do
        self._EchelonData.MemberIndex = XDataCenter.BfrtManager.TeamPosConvert(i)
        self._EchelonData.RequireAbility = XDataCenter.BfrtManager.GetEchelonRequireAbility(self._EchelonData.EchelonId)

        if not self.GirdEchelonMemberList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelonMember)
            local grid = XUiGridEchelonMember.New(self, ui, self._EchelonData)
            grid.Transform:SetParent(self.PanelEchelonMembers, false)
            grid.GameObject:SetActiveEx(true)
            grid.GameObject.name = "GridEchelonMember" .. i
            self.GirdEchelonMemberList[i] = grid
        else
            self.GirdEchelonMemberList[i]:UpdateMemberInfo(self._EchelonData)
        end
    end
end

function XUiGridEchelon:_UpdateEchelonConditionState()
    local requireAbility = XDataCenter.BfrtManager.GetEchelonRequireAbility(self._EchelonData.EchelonId)
    self.TxtRequireAbility.text = requireAbility

    local characterCount = 0
    local allOverAbility = true
    local team = self._EchelonData.TeamList[self._EchelonData.EchelonIndex]
    for _, characterId in pairs(team) do
        if characterId > 0 then
            characterCount = characterCount + 1
            local char = XMVCA.XCharacter:GetCharacter(characterId)
            local nowAbility = char and char.Ability or 0
            if nowAbility < requireAbility then
                allOverAbility = false
                break
            end
        end
    end

    local retRequireNum = characterCount >= self._EchelonData.EchelonRequireCharacterNum

    local retCondition = self._EchelonData.ConditionId <= 0 or XConditionManager.CheckCondition(self._EchelonData.ConditionId, team)
    self.TxtExtraCondition.color = CONDITION_COLOR[retCondition]

    local pass = allOverAbility and retCondition and retRequireNum
    self.ImgNotPassCondition.gameObject:SetActiveEx(false)
    self.ConditionPassed = pass
end

function XUiGridEchelon:_UpdatePass()
    if self.Yazhichenggong then
        self.Yazhichenggong.gameObject:SetActiveEx(self._EchelonData.IsRecordPass)
    end
end
--endregion

--region Ui - BntListener
function XUiGridEchelon:AddBtnListener()
    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnRecovery.CallBack = function() self:OnBtnStageResetClick() end
end

function XUiGridEchelon:OnBtnLeaderClick()
    if self._EchelonData.IsRecordPass then
        XDataCenter.BfrtManager.TipStageIsPass()
        return
    end
    local team = {}
    local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(self._EchelonData.EchelonId, self._EchelonData.BfrtGroupId, self._EchelonData.EchelonIndex)

    team = self._EchelonData.TeamList[self._EchelonData.EchelonIndex]

    XLuaUiManager.Open("UiNewRoomSingleTip", self, team, captainPos, function(index)
        XDataCenter.BfrtManager.SetTeamCaptainPos(self._EchelonData.EchelonId, index)
        self:UpdateNumberLeader()
    end)
end

function XUiGridEchelon:OnBtnStageResetClick()
    if not self._EchelonData.IsRecordPass then
        return
    end
    self._EchelonData.IsRecordPass = false
    XDataCenter.BfrtManager.RequestResetGroupStage(self._EchelonData.StageId, false, function()
        self:UpdateEchelonInfo(self._EchelonData)
    end)
end
--endregion

--region Event
function XUiGridEchelon:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_RESET_STAGE_RECORD, self._RefreshEchelonByResetRecord, self)
end

function XUiGridEchelon:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_RESET_STAGE_RECORD, self._RefreshEchelonByResetRecord, self)
end

function XUiGridEchelon:AddOnStartEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_OPEN_BATTLE_ROOM_DETAIL, self._OpenBattleRoomDetail, self)
end

function XUiGridEchelon:RemoveOnDestroyListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_OPEN_BATTLE_ROOM_DETAIL, self._OpenBattleRoomDetail, self)
end
--endregion

function XUiGridEchelon:CheckIsInPassTeam(characterId, echelonIndex)
    return self.Parent:CheckIsInPassTeam(characterId, echelonIndex)
end

return XUiGridEchelon