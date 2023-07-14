local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

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
    self:CheckTeamNum()
    self:InitPanelColour()
    self:UpdateImgLeaderTag()
    self:UpdateImgFirstRole()
    self:UpdateCharacterInfo()
end

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

function XUiGridEchelonMember:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiGridEchelonMember:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridEchelonMember:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridEchelonMember:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end
-- auto
function XUiGridEchelonMember:OnBtnClickClick()
    if self.MemberIndex > self.EchelonRequireCharacterNum then
        return
    end

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
            return self.RootUi:CheckIsInTeamList(characterId)
        end,
        CharacterSwapEchelonCb = function(oldCharacterId, newCharacterId)
            return self.RootUi:CharacterSwapEchelon(oldCharacterId, newCharacterId)
        end,
        TeamResultCb = function(team)
            self.RootUi:UpdateTeamInfo(team)
        end,
    }
    if XTool.USENEWBATTLEROOM then
        RunAsyn(function()
            XLuaUiManager.Open("UiBattleRoomRoleDetail", self.StageId
                , XDataCenter.TeamManager.CreateTempTeam(self.TeamList[self.EchelonIndex])
                , self.MemberIndex
                -- 硬编码，这个界面过度依赖页面数据
                , self:GetProxyInstance(viewData))
        end)
    else
        XLuaUiManager.Open("UiBfrtRoomCharacter", viewData)
    end
end

function XUiGridEchelonMember:GetProxyInstance(viewData)
    return {
        AOPCloseBefore = function(proxy, rootUi)
            self.RootUi:UpdateTeamInfo(rootUi.Team:GetEntityIds())
        end,
        AOPOnDynamicTableEventAfter = function(proxy, rootUi, event, index, grid)
            local entity = rootUi.DynamicTable.DataSource[index]
            local inEchelonIndex, inEchelonType = self.RootUi:CheckIsInTeamList(entity:GetId())
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                grid.ImgInTeam.gameObject:SetActiveEx(false)
                grid.PanelTeamSupport.gameObject:SetActiveEx(false)
                if inEchelonIndex then
                    if inEchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
                        grid.TxtInTeam.text = CS.XTextManager.GetText("BfrtFightEchelonTitleSimple", inEchelonIndex)
                        grid.ImgInTeam.gameObject:SetActiveEx(true)
                    elseif inEchelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
                        grid.TxtTeamSupport.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitleSimple", inEchelonIndex)
                        grid.PanelTeamSupport.gameObject:SetActiveEx(true)
                    end
                end
            end
        end,
        AOPOnBtnJoinTeamClickedBefore = function(proxy, rootUi)
            local inEchelonIndex, inEchelonType = self.RootUi:CheckIsInTeamList(rootUi.CurrentEntityId)
            if inEchelonIndex and inEchelonType then
                local oldCharacterId = rootUi.Team:GetEntityIdByTeamPos(rootUi.Pos)
                local newCharacterId = rootUi.CurrentEntityId
                local finishCallback = function ()
                    self.RootUi:CharacterSwapEchelon(newCharacterId, oldCharacterId)
                    rootUi.Team:UpdateEntityTeamPos(rootUi.CurrentEntityId, rootUi.Pos, true)
                    rootUi:Close(true)
                end
                local sureCallback = function()    
                    if not rootUi:CheckCanJoin(rootUi.CurrentEntityId, finishCallback) then
                        return
                    end
                    finishCallback()
                end    
                local title = CS.XTextManager.GetText("BfrtDeployTipTitle")
                local characterName = XCharacterConfigs.GetCharacterName(newCharacterId)
                local oldEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(inEchelonType, inEchelonIndex)
                local newEchelon = XDataCenter.BfrtManager.GetEchelonNameTxt(viewData.EchelonType, viewData.EchelonIndex)
                local content = CS.XTextManager.GetText("BfrtDeployTipContent", characterName, oldEchelon, newEchelon)
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, sureCallback)
                return true
            end
        end,
        GetChildPanelData = function (proxy)
            if proxy.ChildPanelData == nil then
                proxy.ChildPanelData = {
                    assetPath = XUiConfigs.GetComponentUrl("UiPanelBfrtRoomRoleDetail"),
                    proxy = require("XUi/XUiBfrt/XUiPanelBfrtRoomRoleDetail"),
                    proxyArgs = { viewData, "CurrentEntityId", "Team" }
                }
            end
            return proxy.ChildPanelData
        end,
        GetIsShowRoleDetail = function()
            return false
        end
    }
end

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
        self.RImgRoleHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
        self.PanelSlect.gameObject:SetActive(true)
        self.PanelEmpty.gameObject:SetActive(false)
        self.PanelLock.gameObject:SetActive(false)

        local char = XDataCenter.CharacterManager.GetCharacter(characterId)
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

return XUiGridEchelonMember