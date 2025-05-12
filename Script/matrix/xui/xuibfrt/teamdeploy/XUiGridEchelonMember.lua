local XUiBfrtBattleRoomDetailRoleGrid = require("XUi/XUiBfrt/BattleRoom/XUiBfrtBattleRoomDetailRoleGrid")
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiBfrt/TeamDeploy/XUiBfrtBattleRoleRoomProxy")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

---@class XUiGridEchelonMember
local XUiGridEchelonMember = XClass(nil, "XUiGridEchelonMember")

--位置对应的颜色框
local MEMBER_POS_COLOR = {
    [1] = "ImgRed",
    [2] = "ImgBlue",
    [3] = "ImgYellow",
}

function XUiGridEchelonMember:Ctor(rootUi, ui, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XUiGridEchelon
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self:ResetMemberInfo()
    self:UpdateMemberInfo(data)
end

function XUiGridEchelonMember:ResetMemberInfo()
    self.MemberIndex = nil
    self.RequireAbility = nil
    self.StageId = nil
    self.EchelonRequireCharacterNum = nil
    self.EchelonIndex = nil
    self.EchelonId = nil
    self.EchelonType = nil
    self.TeamList = {}
    self.CharacterIdListWrap = {}
    self.TeamHasLeader = false
    self.TeamHasFirstFight = false

    self.ImgLeaderTag.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.PanelSlect.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelColour.gameObject:SetActiveEx(false)
    self.ImgBlue.gameObject:SetActiveEx(false)
    self.ImgRed.gameObject:SetActiveEx(false)
    self.ImgYellow.gameObject:SetActiveEx(false)
end

---@param data XBfrtEchelonData
function XUiGridEchelonMember:UpdateMemberInfo(data)
    self.GroupId = data.BfrtGroupId
    self.MemberIndex = data.MemberIndex
    self.EchelonRequireCharacterNum = data.EchelonRequireCharacterNum
    if self.MemberIndex > self.EchelonRequireCharacterNum then
        return
    end

    self.RequireAbility = data.RequireAbility
    self.StageId = data.StageId
    self.EchelonIndex = data.EchelonIndex
    self.EchelonId = data.EchelonId
    self.EchelonType = data.EchelonType
    self.TeamList = data.TeamList
    self.CharacterIdListWrap = data.CharacterIdListWrap
    self.TeamHasLeader = data.TeamHasLeader
    self.TeamHasFirstFight = data.TeamHasFirstFight
    self._IsRecordPass = data.IsRecordPass
    self:CheckTeamNum()
    self:InitPanelColour()
    self:UpdateImgLeaderTag()
    self:UpdateImgFirstRole()
    self:UpdateCharacterInfo()
end

--region Init
-- auto
-- Automatic generation of code, forbid to edit
function XUiGridEchelonMember:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridEchelonMember:AutoInitUi()
    self.BtnClick = self.Transform:Find("BtnClick"):GetComponent("Button")
    self.PanelSlect = self.Transform:Find("PanelSlect")
    self.ImgMask = self.Transform:Find("PanelSlect/ImgMask"):GetComponent("Image")
    self.RImgRoleHead = self.Transform:Find("PanelSlect/ImgMask/RImgRoleHead"):GetComponent("RawImage")
    self.TxtNowAbility = self.Transform:Find("PanelSlect/PanelNotPassCondition/TxtNowAbility"):GetComponent("Text")
    self.PanelEmpty = self.Transform:Find("PanelEmpty")
    self.PanelColour = self.Transform:Find("PanelColour")
    self.ImgYellow = self.Transform:Find("PanelColour/ImgYellow"):GetComponent("Image")
    self.ImgBlue = self.Transform:Find("PanelColour/ImgBlue"):GetComponent("Image")
    self.ImgRed = self.Transform:Find("PanelColour/ImgRed"):GetComponent("Image")
    self.PanelLock = self.Transform:Find("PanelLock")
end
--endregion

--region Ui - Member
function XUiGridEchelonMember:UpdateImgLeaderTag()
    if not self.TeamHasLeader then
        return
    end

    local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(self.EchelonId, self.GroupId, self.EchelonIndex)
    if self.MemberIndex <= self.EchelonRequireCharacterNum and self.MemberIndex == captainPos then
        self.ImgLeaderTag.gameObject:SetActive(true)
    else
        self.ImgLeaderTag.gameObject:SetActive(false)
    end
end

function XUiGridEchelonMember:UpdateImgFirstRole()
    if not self.TeamHasFirstFight then
        return
    end

    local firstFightPos = XDataCenter.BfrtManager.GetTeamFirstFightPos(self.EchelonId, self.GroupId, self.EchelonIndex)

    if self.MemberIndex <= self.EchelonRequireCharacterNum and self.MemberIndex == firstFightPos then
        self.ImgFirstRole.gameObject:SetActive(true)
    else
        self.ImgFirstRole.gameObject:SetActive(false)
    end
end

function XUiGridEchelonMember:UpdateCharacterInfo()
    if self.MemberIndex > self.EchelonRequireCharacterNum then
        return
    end

    local characterId = self.TeamList[self.EchelonIndex][self.MemberIndex]
    if not characterId or characterId == 0 then
        if self.MemberIndex <= self.EchelonRequireCharacterNum then
            --没出人
            self.PanelSlect.gameObject:SetActive(false)
            self.PanelEmpty.gameObject:SetActive(true)
            self.PanelLock.gameObject:SetActive(false)
        else
            --不能上人（要求两个人，第三个格子的状态）
            self.PanelSlect.gameObject:SetActive(false)
            self.PanelEmpty.gameObject:SetActive(false)
            self.PanelLock.gameObject:SetActive(true)
        end
    else
        --上了人
        self.RImgRoleHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        self.PanelSlect.gameObject:SetActive(true)
        self.PanelEmpty.gameObject:SetActive(false)
        self.PanelLock.gameObject:SetActive(false)

        local char = XMVCA.XCharacter:GetCharacter(characterId)
        local nowAbility = char and char.Ability or 0
        self.TxtNowAbility.text = math.floor(nowAbility)
        self.TxtNowAbility.color = CONDITION_COLOR[nowAbility >= self.RequireAbility]
    end
end

function XUiGridEchelonMember:InitPanelColour()
    if not self.TeamHasLeader then
        self.PanelColour.gameObject:SetActive(false)
        return
    end
    self[MEMBER_POS_COLOR[self.MemberIndex]].gameObject:SetActive(true)
    self.PanelColour.gameObject:SetActive(true)
end

function XUiGridEchelonMember:CheckTeamNum()
    self.TeamList[self.EchelonIndex] = self.TeamList[self.EchelonIndex] or { 0, 0, 0 }
    for i = #self.TeamList[self.EchelonIndex], self.EchelonRequireCharacterNum + 1, -1 do
        self.TeamList[self.EchelonIndex][i] = 0
    end
end
--endregion

--region Ui - BattleRoom
function XUiGridEchelonMember:GetProxyInstance(viewData)
    return {
        AOPCloseBefore = function(proxy, rootUi)
            self.RootUi:UpdateTeamInfo(rootUi.Team:GetEntityIds())
        end,
        --v2.6 新编队角色筛选器不用AOP
        --AOPOnDynamicTableEventAfter = function(proxy, rootUi, event, index, grid)
        --local entity = rootUi.DynamicTable.DataSource[index]
        --if not entity then
        --    return
        --end
        --local inEchelonIndex, inEchelonType = self.RootUi:CheckIsInTeamList(entity:GetId())
        --if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        --    grid.ImgInTeam.gameObject:SetActiveEx(false)
        --    grid.PanelTeamSupport.gameObject:SetActiveEx(false)
        --    if inEchelonIndex then
        --        if inEchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
        --            grid.TxtInTeam.text = CS.XTextManager.GetText("BfrtFightEchelonTitleSimple", inEchelonIndex)
        --            grid.ImgInTeam.gameObject:SetActiveEx(true)
        --        elseif inEchelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
        --            grid.TxtTeamSupport.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitleSimple", inEchelonIndex)
        --            grid.PanelTeamSupport.gameObject:SetActiveEx(true)
        --        end
        --    end
        --end
        --end,
        AOPOnBtnJoinTeamClickedBefore = function(proxy, rootUi)
            local inEchelonIndex, inEchelonType = XDataCenter.BfrtManager.CheckIsInTeamList(rootUi.CurrentEntityId)
            local groupId = self.GroupId
            if inEchelonIndex and inEchelonType then
                local stageIds = XDataCenter.BfrtManager.GetStageIdList(groupId)
                if XDataCenter.BfrtManager.CheckIsGroupStageRecordStage(groupId, stageIds[inEchelonIndex]) then
                    XDataCenter.BfrtManager.TipStageIsPass()
                    return true
                end
                local oldCharacterId = rootUi.Team:GetEntityIdByTeamPos(rootUi.Pos)
                local newCharacterId = rootUi.CurrentEntityId
                local finishCallback = function()
                    XEventManager.DispatchEvent(XEventId.EVENT_BFRT_TEAM_SWAP, oldCharacterId, newCharacterId, self.MemberIndex)
                    --rootUi.Team:UpdateEntityTeamPos(rootUi.CurrentEntityId, rootUi.Pos, true)
                    rootUi:Close(true)
                end
                local sureCallback = function()
                    if not rootUi:CheckCanJoin(rootUi.CurrentEntityId, finishCallback) then
                        return
                    end
                    finishCallback()
                end
                local title = CS.XTextManager.GetText("BfrtDeployTipTitle")
                local characterName = XMVCA.XCharacter:GetCharacterName(newCharacterId)
                local oldEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(inEchelonType, inEchelonIndex)
                local newEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(viewData.EchelonType, viewData.EchelonIndex)
                local content = CS.XTextManager.GetText("BfrtDeployTipContent", characterName, oldEchelon, newEchelon)
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, sureCallback)
                return true
            end
        end,
        GetChildPanelData = function(proxy)
            if proxy.ChildPanelData == nil then
                proxy.ChildPanelData = {
                    assetPath = XUiConfigs.GetComponentUrl("UiPanelBfrtRoomRoleDetail"),
                    proxy = require("XUi/XUiBfrt/BattleRoom/XUiPanelBfrtRoomRoleDetail"),
                    proxyArgs = { viewData, "CurrentEntityId", "Team", function(characterId)
                        return self.RootUi:CheckIsInPassTeam(characterId, self.EchelonIndex)
                    end }
                }
            end
            return proxy.ChildPanelData
        end,
        GetIsShowRoleDetail = function()
            return false
        end,
        GetGridProxy = function()
            return XUiBfrtBattleRoomDetailRoleGrid
        end,
        GetGridExParams = function()
            return { function(characterId)
                return XDataCenter.BfrtManager.CheckIsInTeamList(characterId)
            end }
        end,
        -- v2.6 新编队角色筛选器
        GetFilterControllerConfig = function()
            return
        end
    }
end
--endregion

--region Ui - BtnListener
function XUiGridEchelonMember:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end

---@class XUiGridEchelonMemberViewData
---@field EchelonId
---@field BfrtGroupId
---@field RequireAbility
---@field TeamCharacterIdList
---@field TeamSelectPos
---@field EchelonIndex
---@field EchelonType
---@field StageId
---@field EchelonRequireCharacterNum
---@field CheckIsInTeamListCb
---@field CharacterSwapEchelonCb
---@field TeamResultCb

function XUiGridEchelonMember:OnOpenBattleRoleRoomDetail()
    if self._IsRecordPass then
        XDataCenter.BfrtManager.TipStageIsPass()
        return
    end
    if self.MemberIndex > self.EchelonRequireCharacterNum then
        return
    end

    ---@type XUiGridEchelonMemberViewData
    local viewData = {
        EchelonId = self.EchelonId,
        BfrtGroupId = self.GroupId,
        RequireAbility = self.RequireAbility,
        TeamCharacterIdList = self.TeamList[self.EchelonIndex],
        TeamSelectPos = self.MemberIndex,
        EchelonIndex = self.EchelonIndex,
        EchelonType = self.EchelonType,
        StageId = self.StageId,
        EchelonRequireCharacterNum = self.EchelonRequireCharacterNum,
        CheckIsInTeamListCb = function(characterId)
            return XDataCenter.BfrtManager.CheckIsInTeamList(characterId)
        end,
        CharacterSwapEchelonCb = function(oldCharacterId, newCharacterId)
            XEventManager.DispatchEvent(XEventId.EVENT_BFRT_TEAM_SWAP, oldCharacterId, newCharacterId, self.MemberIndex)
        end,
        TeamResultCb = function(team)
            self.RootUi:UpdateTeamInfo(team)
        end,
    }
    RunAsyn(function()
        XLuaUiManager.Open("UiBattleRoomRoleDetail", self.StageId
        , XDataCenter.BfrtManager.GetTeam()
        , self.MemberIndex
        -- 硬编码，这个界面过度依赖页面数据
        , self:GetProxyInstance(viewData))
    end)
end

function XUiGridEchelonMember:OnBtnClickClick()
    local createTeamData = {
        EchelonIndex = self.EchelonIndex,
        BfrtGroupId = self.GroupId,
        EchelonId = self.EchelonId,
        TeamCharacterIdList = self.TeamList[self.EchelonIndex],
    }
    XDataCenter.BfrtManager.SetCurSelectTeamIdx(self.EchelonIndex)
    XDataCenter.BfrtManager.SetCurSelectFightType(self.EchelonType)
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId, XDataCenter.BfrtManager.GetTeam(createTeamData), XUiBattleRoleRoomDefaultProxy)
end
--endregion

return XUiGridEchelonMember