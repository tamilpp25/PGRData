--虚拟地平线预设队伍界面
local XUiExpeditionDefaultTeam = XLuaUiManager.Register(XLuaUi, "UiExpeditionDefaultTeam")
local DefaultTeamScript = require("XUi/XUiExpedition/Recruit/XUiExpeditionDefaultTeam/XUiExpeditionDefaultTeamGrid")
function XUiExpeditionDefaultTeam:OnStart(onCloseCb)
    self.GridTeam.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = handler(self, self.OnClickClose)
    self.TxtTipsDesc.text = string.gsub(XUiHelper.GetText("ExpeditionDefaultTeamTips"), "\\n", "\n")
    self.OnCloseCb = onCloseCb
    self.TeamGrids = {}
end

function XUiExpeditionDefaultTeam:OnEnable()
    self:InitTeamList()
end

function XUiExpeditionDefaultTeam:OnDisable()
    
end

function XUiExpeditionDefaultTeam:OnGetEvents()
    return { XEventId.EVENT_EXPEDITION_SELECT_DEFAULT_TEAM_SUCCESS }
end

function XUiExpeditionDefaultTeam:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_EXPEDITION_SELECT_DEFAULT_TEAM_SUCCESS then
        self:OnClose()
    end
end

function XUiExpeditionDefaultTeam:InitTeamList()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local allTeamCfg = eActivity:GetDefaultTeamCfg()
    for index, teamCfg in pairs(allTeamCfg or {}) do
        if not self.TeamGrids[index] then
            local gridGo = CS.UnityEngine.Object.Instantiate(self.GridTeam)
            gridGo.transform:SetParent(self.PanelContent, false)
            self.TeamGrids[index] = DefaultTeamScript.New(gridGo, teamCfg, self)
        end
    end
end

function XUiExpeditionDefaultTeam:OnClickClose()
    self:OnClose()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end

function XUiExpeditionDefaultTeam:OnClose()
    self:Close()
end

function XUiExpeditionDefaultTeam:SetSelect(teamId)
    -- 切换默认队伍
    local confirmCb = function()
        XDataCenter.ExpeditionManager.SelectDefaultTeam(teamId)
    end
    -- 判断是否有默认队伍
    local defaultTeamId = XDataCenter.ExpeditionManager.GetDefaultTeamId()
    if not XTool.IsNumberValid(defaultTeamId) then
        confirmCb()
        XDataCenter.ExpeditionManager.RefreshRecruit() -- 第一次选择默认队伍的同时需要刷新一次招募商店
        return
    end
    -- 弹出提示
    local title = CSXTextManagerGetText("ExpeditionDefaultTeamConfirmTitle")
    local targetFullNameList = self:GetFullName(teamId)
    local defaultFullNameList = self:GetFullName(defaultTeamId)
    local content = CSXTextManagerGetText("ExpeditionDefaultTeamConfirmContent", defaultFullNameList[1], defaultFullNameList[2], targetFullNameList[1], targetFullNameList[2])
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiExpeditionDefaultTeam:GetCharaFullName(baseId)
    local baseECharaCfg = XExpeditionConfig.GetBaseCharacterCfgById(baseId)
    return XCharacterConfigs.GetCharacterFullNameStr(baseECharaCfg.CharacterId)
end

function XUiExpeditionDefaultTeam:GetFullName(teamId)
    local teamCfg = teamId and teamId > 0 and XExpeditionConfig.GetDefaultTeamCfgByTeamId(teamId)
    local fullNameList = {}
    for index, charaId in pairs(teamCfg.ECharacterIds or {}) do
        local baseId = XExpeditionConfig.GetBaseIdByECharId(charaId)
        local fullName = self:GetCharaFullName(baseId)
        fullNameList[index] = fullName
    end
    return fullNameList
end