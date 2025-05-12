local XUiGridTeamRole = require("XUi/XUiRoomTeamPrefab/XUiGridTeamRole")
local CSXTextManagerGetText = CS.XTextManager.GetText
---@class XUiGridTeam
local XUiGridTeam = XClass(nil, "XUiGridTeam")

local MAX_TEAM_MEMBER = 3 --队员最大数量

function XUiGridTeam:Ctor(rootUi, ui, characterLimitType, limitBuffId, stageType, teamGridId, stageId)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.StageType = stageType
    self:AddListener()
    self:InitFirstFightTabBtnGroup()
    self.GridTeamRole.gameObject:SetActive(false)
    self.TeamRoles = {}
    self.CharacterLimitType = characterLimitType
    self.LimitBuffId = limitBuffId
    self.TeamGridId = teamGridId
    self.StageId = stageId
    self:OnAnimationSetChange()
end

function XUiGridTeam:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridTeam:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridTeam:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridTeam:AddListener()
    self.BtnCaptain.CallBack = function()
        self:OnBtnCaptainClick()
    end
    self.BtnReName.CallBack = function()
        self:OnBtnReNameClick()
    end
    self.BtnCover.CallBack = function()
        self:OnBtnCoverClick()
    end

    local func
    if self:IsPivotCombat() then
        func = handler(self, self.OnPivotCombatBtnChoicesClick)
    else
        func = handler(self, self.OnSelectCallback)
    end
    self.ChoicesCallBack = func

    self:RegisterClickEvent(self.BtnChoices, self.OnBtnChoicesClick)
    self.BtnAnimationSet.CallBack = handler(self, self.OnBtnAnimationSetClick)
end

function XUiGridTeam:InitFirstFightTabBtnGroup()
    local tabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.PanelTabFirstFight:Init(tabGroup, function(tabIndex) self:OnFirstFightTabClick(tabIndex) end)
end

---
--- 设置首发位
function XUiGridTeam:OnFirstFightTabClick(tabIndex)
    if self.TeamData.FirstFightPos == tabIndex then
        return
    end

    self.TeamData.FirstFightPos = tabIndex
    XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
    self:RefreshTeamRoles()
end

---
--- 设置队长
function XUiGridTeam:SelectCaptain(index)
    if self.TeamData.CaptainPos == index then
        return
    end

    self.TeamData.CaptainPos = index
    XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
    self:RefreshTeamRoles()
end

function XUiGridTeam:Refresh(teamData, index)
    self:HandleCharacterType(teamData)
    self.TeamData = teamData
    self:SetName(teamData.TeamName or CS.XTextManager.GetText("TeamPrefabDefaultName", index))
    self.PanelTabFirstFight:SelectIndex(teamData.FirstFightPos)
    self:RefreshTeamRoles()
end

function XUiGridTeam:SetName(name)
    self.TextName.text = name
end

function XUiGridTeam:ChangeName(confirmName, closeCb)
    local teamData = {}
    teamData.TeamId = self.TeamData.TeamId
    teamData.CaptainPos = self.TeamData.CaptainPos
    teamData.FirstFightPos = self.TeamData.FirstFightPos
    teamData.TeamData = self.TeamData.TeamData
    teamData.TeamName = confirmName

    XDataCenter.TeamManager.SetPlayerTeam(teamData, true, function()
        self.TeamData.TeamName = confirmName
        self:SetName(confirmName)
        if closeCb then
            closeCb()
        end
    end)
end

function XUiGridTeam:HandleCharacterType(teamData)
    local characterType = 0
    for _, charId in ipairs(teamData.TeamData) do
        if charId > 0 then
            local charTemplate = XMVCA.XCharacter:GetCharacterTemplate(charId)
            if charTemplate then
                characterType = charTemplate.Type
                break
            end
        end
    end
    self.CharacterType = characterType
end

-- 获取编队是否为混合角色类型
function XUiGridTeam:GetTeamIsMixType()
    local countDic = {}
    for _, charId in pairs(self.TeamData.TeamData) do
        if charId > 0 then
            local charTemplate = XMVCA.XCharacter:GetCharacterTemplate(charId)
            if charTemplate then
                countDic[charTemplate.Type] = true
            end
        end
    end
    return table.nums(countDic) > 1
end

function XUiGridTeam:RefreshTeamRoles()
    self:RefreshRoleGrid(2)
    self:RefreshRoleGrid(1)
    self:RefreshRoleGrid(3)
end

function XUiGridTeam:RefreshRoleGrid(pos)
    local grid = self.TeamRoles[pos]
    if not grid then
        local item = CS.UnityEngine.Object.Instantiate(self.GridTeamRole)
        grid = XUiGridTeamRole.New(self.RootUi, item, self.StageId)
        grid.Transform:SetParent(self.PanelCharContent, false)
        grid.GameObject:SetActive(true)
        self.TeamRoles[pos] = grid
    end

    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    grid:Refresh(pos, self.TeamData, characterLimitType, limitBuffId)
end

function XUiGridTeam:OnAnimationSetChange()
    self.BtnAnimationSet.gameObject:SetActiveEx(XMVCA.XFuben:IsFightCgEnable())
end

function XUiGridTeam:SetSelectFasle(pos)
    self.TeamRoles[pos]:SetSelect(false)
    self.TeamRoles[pos].IsClick = false
end

function XUiGridTeam:OnPivotCombatBtnChoicesClick()
    local newTeamData = {}
    local teamData = self.TeamData.TeamData
    local teamMembers = 0
    for _, id in ipairs(teamData) do
        if XTool.IsNumberValid(id) then
            teamMembers = teamMembers + 1
        end
    end
    local lockTeamMembers = 0
    local characterIdDic = XDataCenter.PivotCombatManager.GetLockCharacterDict()
    for id, entityId in ipairs(teamData or {}) do
        local charId = entityId
        if XRobotManager.CheckIsRobotId(entityId) then
            charId = XRobotManager.GetCharacterId(entityId)
        end
        if characterIdDic[charId] then
            lockTeamMembers = lockTeamMembers + 1
            newTeamData[id] = 0
        else
            newTeamData[id] = entityId
        end
    end
    local stage = XDataCenter.PivotCombatManager.GetStage(self.StageId)
    local useLockRole = stage and stage:CanUseLockedRole() or false
    if not useLockRole and lockTeamMembers > 0 then
        if lockTeamMembers >= teamMembers and teamMembers ~= 0 then
            XUiManager.TipText("PivotCombatTeamPrefabLockTeam")
            return
        else
            local confirmCb = function()
                local newTeam = XTool.Clone(self.TeamData)
                newTeam.TeamData = newTeamData

                local characterLimitType = self.CharacterLimitType
                local characterType = self.CharacterType

                local selectFunc = function()
                    XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_SELECT, newTeam)
                    self.RootUi:EmitSignal("RefreshTeamData", newTeam)
                    self.RootUi:Close(newTeam)
                end

                -- 混合类型
                if self:GetTeamIsMixType() then
                    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
                        XUiManager.TipText("TeamCharacterTypeNormalLimitText")
                        return
                    end
                    if characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
                        XUiManager.TipText("TeamCharacterTypeIsomerLimitText")
                        return
                    end
                end

                if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
                    if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
                        XUiManager.TipText("TeamCharacterTypeNormalLimitText")
                        return
                    end
                elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
                    if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
                        XUiManager.TipText("TeamCharacterTypeIsomerLimitText")
                        return
                    end
                end

                selectFunc()
            end
            local title = XUiHelper.GetText("BfrtDeployTipTitle")
            local content = XUiHelper.GetText("PivotCombatTeamPrefabLockCharacter")
            XUiManager.DialogTip(title, content, nil, nil, confirmCb)
        end
    else
        self:OnSelectCallback()
    end
end

function XUiGridTeam:OnBtnChoicesClick()
    local func = self.ChoicesCallBack
    if not func then return end
    
    --检查是否有技能或携带成员发生变更
    local checkFunc = function()
        local partnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(self.TeamData.TeamId)
        local prefabRoleList = self.TeamData.TeamData

        if self:IsEmptyTeam(prefabRoleList) then
            return false
        end
        
        for pos = 1, MAX_TEAM_MEMBER do
            local pId = partnerPrefab:GetPartnerIdByPos(pos)
            if not XTool.IsNumberValid(pId) then
                goto Continue
            end
            --判断真实携带者与预设携带者 
            local partner = XDataCenter.PartnerManager.GetPartnerEntityById(pId)
            local chrId = partner:GetCharacterId() --当前辅助机真实的携带者
            if XTool.IsNumberValid(chrId) and chrId ~= prefabRoleList[pos] then
                return true
            end
            --判断辅助机技能
            if partnerPrefab:IsSkillChangeWithPrefab2Group(pId) then
                return true
            end

            :: Continue ::
        end
        return false
    end
    
    if checkFunc() then
        XLuaUiManager.Open("UiPartnerPresetPopup", nil, self.TeamData, false, func)
    else
        func()
    end
end

function XUiGridTeam:OnSelectCallback()
    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    local characterType = self.CharacterType

    local selectFunc = function()
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_SELECT, self.TeamData)
        self.RootUi:EmitSignal("RefreshTeamData", self.TeamData)
        if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") then
            self.RootUi:Close(self.TeamData)
        end
    end

    -- 混合类型
    if self:GetTeamIsMixType() then
        if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
            XUiManager.TipText("TeamCharacterTypeNormalLimitText")
            return
        end
        if characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
            XUiManager.TipText("TeamCharacterTypeIsomerLimitText")
            return
        end
    end

    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            XUiManager.TipText("TeamCharacterTypeNormalLimitText")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            XUiManager.TipText("TeamCharacterTypeIsomerLimitText")
            return
        end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        --     if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
        --         local buffDes = XFubenConfigs.GetBuffDes(limitBuffId)
        --         local content = CSXTextManagerGetText("TeamPrefabCharacterTypeLimitTipIsomerDebuff", buffDes)
        --         local sureCallBack = selectFunc
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
        --         return
        --     end
        -- elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        --     if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
        --         local buffDes = XFubenConfigs.GetBuffDes(limitBuffId)
        --         local content = CSXTextManagerGetText("TeamPrefabCharacterTypeLimitTipNormalDebuff", buffDes)
        --         local sureCallBack = selectFunc
        --         XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
        --         return
        --     end
    end

    XDataCenter.PartnerManager.PartnerMultiCarryAndSkillRequest(self.TeamData, selectFunc)
end

function XUiGridTeam:OnBtnCaptainClick()
    XLuaUiManager.Open("UiNewRoomSingleTip", self, self.TeamData.TeamData, self.TeamData.CaptainPos, function(index)
        self:SelectCaptain(index)
    end)
end

function XUiGridTeam:OnBtnReNameClick()
    XLuaUiManager.Open("UiTeamPrefabReName", function(newName, closeCb)
        self:ChangeName(newName, closeCb)
    end)
end

function XUiGridTeam:OnBtnCoverClick()
    --目前只支持了UiBattleRoleRoom/UiNewRoomSingle内的队伍数据进行覆盖
    local team = self.RootUi.Team
    if not team then
        XUiManager.TipText("RoomTeamPrefabNotSupport")
        return
    end
    local teamData
    --兼容旧的队伍系统
    if team.SwithToOldTeamData then
        teamData = team:SwithToOldTeamData()
    else
        teamData = XTool.Clone(team)
    end
    --判断出场设置有没有变化
    local isAnimChange = false
    if XMVCA.XFuben:IsFightCgEnable() then
        if teamData.EnterCgIndex ~= self.TeamData.EnterCgIndex or teamData.SettleCgIndex ~= self.TeamData.SettleCgIndex then
            isAnimChange = true
        end
    end
    if self:IsSameTeam(teamData) and not isAnimChange then
        XUiManager.TipText("RoomTeamPrefabSameTeam")
    else
        XLuaUiManager.Open("UiPartnerPresetPopup", teamData, self.TeamData, true, handler(self, self.OnCoverCallback))
    end
    
end

function XUiGridTeam:OnCoverCallback()
    --目前只支持了UiBattleRoleRoom/UiNewRoomSingle内的队伍数据进行覆盖
    local team = self.RootUi.Team
    if not team then
        XUiManager.TipText("RoomTeamPrefabNotSupport")
        return
    end
    local teamData
    --兼容旧的队伍系统
    if team.SwithToOldTeamData then
        teamData = team:SwithToOldTeamData()
    else
        teamData = XTool.Clone(team)
    end
    local entityIds = teamData.TeamData or {}
    for _, entityId in ipairs(entityIds) do
        if XRobotManager.CheckIsRobotId(entityId) then
            XUiManager.TipText("TeamPrefabHasRobotTips")
            return
        elseif XTool.IsNumberValid(entityId) then
            local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(entityId)
            if partner and XRobotManager.CheckIsPartnerRobotId(partner:GetTemplateId()) then
                XUiManager.TipText("TeamPrefabHasRobotTips")
                return
            end
        end
    end
    local partnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(self.TeamData.TeamId)
    
    --刷新队伍数据
    self:HandleCharacterType(teamData)
    self.TeamData.CaptainPos = teamData.CaptainPos
    self.TeamData.FirstFightPos = teamData.FirstFightPos
    self.TeamData.EnterCgIndex = teamData.EnterCgIndex or 0
    self.TeamData.SettleCgIndex = teamData.SettleCgIndex or 0
    self.TeamData.TeamData = XTool.Clone(teamData.TeamData)
    self.PanelTabFirstFight:SelectIndex(self.TeamData.FirstFightPos)
    self:RefreshTeamRoles()
    --刷新辅助机数据
    partnerPrefab:CoverByTeam(self.TeamData.TeamData)
    XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
    
end

function XUiGridTeam:OnBtnAnimationSetClick()
    XLuaUiManager.OpenWithCloseCallback("UiPopupAnimationSet", function()
        XDataCenter.TeamManager.SetPlayerTeam(self.TeamData, true)
    end, self.TeamData)
end

--===========================================================================
 ---@desc 队伍成员是否为空
--===========================================================================
function XUiGridTeam:IsEmptyTeam(teamData)
    if not teamData or XTool.IsTableEmpty(teamData) then
        return true
    end

    for _, chrId in ipairs(teamData) do
        --队伍里有角色
        if XTool.IsNumberValid(chrId) then
            return false
        end
    end
    return true
end

--===========================================================================
 ---@desc 是否是同一个队伍
--===========================================================================
function XUiGridTeam:IsSameTeam(teamData)
    --队长位置
    if teamData.CaptainPos ~= self.TeamData.CaptainPos then
        return false
    end
    --首发位置
    if teamData.FirstFightPos ~= self.TeamData.FirstFightPos then
        return false
    end
    --判断角色（包括顺序，角色id）
    local teamARoles = teamData.TeamData
    local teamBRoles = self.TeamData.TeamData
    local partnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(self.TeamData.TeamId)
    for idx = 1, MAX_TEAM_MEMBER do
        local groupTeamChrId  = teamARoles[idx]
        local prefabTeamChrId = teamBRoles[idx]
        if groupTeamChrId ~= prefabTeamChrId then
            return false
        end
        --判断是否是同一个辅助机
        local prefabPId = partnerPrefab:GetPartnerIdByPos(idx)
        local groupPId  = XDataCenter.PartnerManager.GetCarryPartnerIdByCarrierId(groupTeamChrId)
        if XTool.IsNumberValid(prefabPId) and prefabPId ~= groupPId then
            return false
        end
        --判断辅助机主被动技能是否一致
        if partnerPrefab:IsSkillChangeWithPrefab2Group(prefabPId) then
            return false
        end
        
    end
    
    return true
end

--==============================
 ---@desc 关卡类型是独域特攻
 ---@return boolean
--==============================
function XUiGridTeam:IsPivotCombat()
    return self.StageType == XDataCenter.FubenManager.StageType.PivotCombat
end

return XUiGridTeam