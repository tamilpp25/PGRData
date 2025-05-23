local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local MAX_GRID_NUM = 3

local XUiGridQuickDeployMember = require("XUi/XUiBfrt/TeamDeploy/XUiGridQuickDeployMember")

---@class XUiGridQuickDeployTeam
local XUiGridQuickDeployTeam = XClass(nil, "XUiGridQuickDeployTeam")

function XUiGridQuickDeployTeam:Ctor(ui, memberClickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XUiGridQuickDeployMember[]
    self.MemberGridList = {}
    self.MemberClickCb = memberClickCb

    XTool.InitUiObject(self)
    self.TabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabFirst:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)

    self.TabGroupCT = {
        self.BtnCaptainRed,
        self.BtnCaptainBlue,
        self.BtnCaptainYellow,
    }
    self.PanelTabCaptain:Init(self.TabGroupCT, function(tabIndex) self:OnClickTabCallBackCT(tabIndex) end)

    self.GridTeamMember.gameObject:SetActiveEx(false)
end

function XUiGridQuickDeployTeam:Refresh(echelonId, team, echelonIndex, echelonType, characterLimitType, groupId)
    local gridList = self.MemberGridList
    self.EchelonId = echelonId

    local stageIds = XDataCenter.BfrtManager.GetStageIdList(groupId)
    self._IsRecordPass = XDataCenter.BfrtManager.CheckIsGroupStageRecordStage(groupId, stageIds[echelonIndex])

    if echelonType == XDataCenter.BfrtManager.EchelonType.Fight then
        self.TextTitle.text = CS.XTextManager.GetText("BfrtFightEchelonTitle", echelonIndex)
    elseif echelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
        self.TextTitle.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitle", echelonIndex)
    end

    for index = 1, MAX_GRID_NUM do
        local pos = XDataCenter.BfrtManager.TeamPosConvert(index)
        local grid = gridList[index]
        local characterId = team[pos]

        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridTeamMember, self.PanelRole)
            local clickCb = function(paramCharacterId, paramGrid, paramPos, cacheTeam, cacheCharacterLimitType)
                if self._IsRecordPass then
                    XDataCenter.BfrtManager.TipStageIsPass()
                    return
                end
                self.MemberClickCb(paramCharacterId, paramGrid, paramPos, cacheTeam, cacheCharacterLimitType)
            end

            grid = XUiGridQuickDeployMember.New(go, pos, clickCb)
            gridList[index] = grid
        end
        local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(echelonId, groupId, echelonIndex)

        grid:Refresh(characterId, team, characterLimitType)
        grid:RefreshCaptainPos(captainPos)
        grid.GameObject:SetActiveEx(false)

        self.TabGroup[pos].gameObject:SetActiveEx(true)
        self.TabGroupCT[pos].gameObject:SetActiveEx(true)
    end

    local echelonRequireCharacterNum = XDataCenter.BfrtManager.GetEchelonNeedCharacterNum(self.EchelonId)
    for pos = 1, echelonRequireCharacterNum do
        local index = XDataCenter.BfrtManager.MemberIndexConvert(pos)
        local grid = gridList[index]
        if grid then
            grid.GameObject:SetActiveEx(true)
        end
    end
    
    --队长/首发
    for i = echelonRequireCharacterNum + 1, #self.TabGroup do
        self.TabGroup[i].gameObject:SetActiveEx(false)
    end
    local firstFightPos = XDataCenter.BfrtManager.GetTeamFirstFightPos(echelonId, groupId, echelonIndex)
    self.PanelTabFirst:SelectIndex(firstFightPos)

    for i = echelonRequireCharacterNum + 1, #self.TabGroupCT do
        self.TabGroupCT[i].gameObject:SetActiveEx(false)
    end
    local captainPos = XDataCenter.BfrtManager.GetTeamCaptainPos(echelonId, groupId, echelonIndex)
    self.PanelTabCaptain:SelectIndex(captainPos)
    
    -- 关卡常序区等区域标记
    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)

    local name = XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    self.TxtRequireCharacter.text = name
end

function XUiGridQuickDeployTeam:OnClickTabCallBack(firstFightPos)
    if self.SelectedIndex and self.SelectedIndex == firstFightPos then
        return
    end
    if self.SelectedIndex and self._IsRecordPass then
        XDataCenter.BfrtManager.TipStageIsPass()
        self.PanelTabFirst:SelectIndex(self.SelectedIndex)
        return
    end
    self.SelectedIndex = firstFightPos

    local echelonId = self.EchelonId
    XDataCenter.BfrtManager.SetTeamFirstFightPos(echelonId, firstFightPos)

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end
end

function XUiGridQuickDeployTeam:OnClickTabCallBackCT(captainPos)
    if self.SelectedIndexCT and self.SelectedIndexCT == captainPos then
        return
    end
    if self.SelectedIndexCT and self._IsRecordPass then
        XDataCenter.BfrtManager.TipStageIsPass()
        self.PanelTabCaptain:SelectIndex(self.SelectedIndexCT)
        return
    end
    self.SelectedIndexCT = captainPos

    local echelonId = self.EchelonId
    XDataCenter.BfrtManager.SetTeamCaptainPos(echelonId, captainPos)

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshCaptainPos(captainPos)
    end
end

return XUiGridQuickDeployTeam