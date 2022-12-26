local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridTeam = XClass(nil, "XUiGridTeam")

function XUiGridTeam:Ctor(rootUi, ui, characterLimitType, limitBuffId, stageType, teamGridId)
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
    if self:IsChessPursuit() then
        self:RegisterClickEvent(self.BtnChoices, self.OnChessPursuitBtnChoicesClick)
    else
        self:RegisterClickEvent(self.BtnChoices, self.OnBtnChoicesClick)
    end

    self.BtnCaptain.CallBack = function()
        self:OnBtnCaptainClick()
    end
    self.BtnReName.CallBack = function()
        self:OnBtnReNameClick()
    end
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
            local charTemplate = XCharacterConfigs.GetCharacterTemplate(charId)
            if charTemplate then
                characterType = charTemplate.Type
                break
            end
        end
    end
    self.CharacterType = characterType
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
        grid = XUiGridTeamRole.New(self.RootUi, item)
        grid.Transform:SetParent(self.PanelCharContent, false)
        grid.GameObject:SetActive(true)
        self.TeamRoles[pos] = grid
    end

    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    grid:Refresh(pos, self.TeamData, characterLimitType, limitBuffId)
end

function XUiGridTeam:SetSelectFasle(pos)
    self.TeamRoles[pos]:SetSelect(false)
    self.TeamRoles[pos].IsClick = false
end

function XUiGridTeam:OnChessPursuitBtnChoicesClick()
    local isInOtherTeam = false
    local isInOtherTeamTemp, teamGridIndex, teamIndex, inOtherTeamCharId
    local teamData = XTool.Clone(self.TeamData.TeamData)
    table.sort(teamData, function(charIdA, charIdB)
        return charIdA < charIdB
    end)
    for _, charId in ipairs(teamData) do
        isInOtherTeamTemp, teamGridIndex = XDataCenter.ChessPursuitManager.CheckIsInChessPursuit(nil, charId, self.TeamGridId)
        if isInOtherTeamTemp then
            inOtherTeamCharId = charId
            isInOtherTeam = true
            break
        end
    end
    if isInOtherTeam then
        local name = XCharacterConfigs.GetCharacterFullNameStr(inOtherTeamCharId)
        local content = CSXTextManagerGetText("ChessPursuitUsePrefabTipsContent", name, teamGridIndex)
        content = string.gsub(content, " ", "\u{00A0}") --不换行空格
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function() self:OnBtnChoicesClick() end)
        return
    end

    self:OnBtnChoicesClick()
end

function XUiGridTeam:OnBtnChoicesClick()
    local characterLimitType = self.CharacterLimitType
    local limitBuffId = self.LimitBuffId
    local characterType = self.CharacterType

    local selectFunc = function()
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_SELECT, self.TeamData)
        self.RootUi:Close()
    end

    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal then
        if characterType == XCharacterConfigs.CharacterType.Isomer then
            XUiManager.TipText("TeamCharacterTypeNormalLimitText")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            XUiManager.TipText("TeamCharacterTypeIsomerLimitText")
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        if characterType == XCharacterConfigs.CharacterType.Isomer then
            local buffDes = XFubenConfigs.GetBuffDes(limitBuffId)
            local content = CSXTextManagerGetText("TeamPrefabCharacterTypeLimitTipIsomerDebuff", buffDes)
            local sureCallBack = selectFunc
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
            return
        end
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        if characterType == XCharacterConfigs.CharacterType.Normal then
            local buffDes = XFubenConfigs.GetBuffDes(limitBuffId)
            local content = CSXTextManagerGetText("TeamPrefabCharacterTypeLimitTipNormalDebuff", buffDes)
            local sureCallBack = selectFunc
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, sureCallBack)
            return
        end
    end

    selectFunc()
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

function XUiGridTeam:IsChessPursuit()
    return self.StageType == XDataCenter.FubenManager.StageType.ChessPursuit
end

return XUiGridTeam