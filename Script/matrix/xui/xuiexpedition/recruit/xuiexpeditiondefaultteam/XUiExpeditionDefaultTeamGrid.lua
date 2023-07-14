--虚像地平线预设队伍选项控件
local XUiExpeditionDefaultTeamGrid = XClass(nil, "XUiExpeditionDefaultTeamGrid")
local HeadScript = require("XUi/XUiExpedition/Recruit/XUiExpeditionDefaultTeam/XUiExpeditionDefaultHead")
local XTeam = require("XEntity/XExpedition/XExpeditionTeam")
function XUiExpeditionDefaultTeamGrid:Ctor(uiGameObject, cfg, defaultTeamUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.GridHead.gameObject:SetActiveEx(false)
    self.DefaultTeamUi = defaultTeamUi
    self:RefreshData(cfg)
    self:RefreshPanels()
end

function XUiExpeditionDefaultTeamGrid:RefreshPanels()
    self:InitSelectState()
    self:InitPanelCombo()
    self:InitPanelTeam()
end

function XUiExpeditionDefaultTeamGrid:InitSelectState()
    self.BtnSelect.CallBack = handler(self, self.OnClickSelect)
    local isUnlock, name = self:CheckTeamIsUnlock(self.TeamCfg.PreStageType)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    if not isUnlock then
        self:SetSelect(false)
        self.BtnSelect.gameObject:SetActiveEx(false)
        self.LockTxt.text = CSXTextManagerGetText("ExpeditionDefaultTeamIsUnlock", name)
    else
        local defaultTeamId = XDataCenter.ExpeditionManager.GetDefaultTeamId()
        local isSelect = self.TeamCfg.TeamId == defaultTeamId
        self:SetSelect(isSelect)
        self.BtnSelect.gameObject:SetActiveEx(not isSelect)
    end
end

function XUiExpeditionDefaultTeamGrid:InitPanelCombo()
    self.ComboPanel = {}
    XTool.InitUiObjectByUi(self.ComboPanel, self.PanelCombo)
    local comboCfg = XExpeditionConfig.GetChildComboByDefaultTeamId(self.TeamCfg.TeamId)
    self.ECombo = XDataCenter.ExpeditionManager.GetComboByChildComboId(comboCfg.Id)
    self.ComboPanel.RImgCombo:SetRawImage(self.ECombo:GetIconPath())
    self.ComboPanel.TxtComboName.text = self.ECombo:GetName()
    -- 技能描述
    self.ComboPanel.TxtSkill.text = XUiHelper.ConvertLineBreakSymbol(self.TeamCfg.TeamDes)
    XUiHelper.RegisterClickEvent(self, self.ComboPanel.RImgCombo, function() self:OnClickCombo() end)
end

function XUiExpeditionDefaultTeamGrid:InitPanelTeam()
    local eCharaIds = self.TeamCfg.ECharacterIds
    self.TeamHeadIcons = {}
    for index, eCharaId in pairs(eCharaIds) do
        if eCharaId and eCharaId > 0 then
            local rank = XExpeditionConfig.GetCharacterCfgById(eCharaId) and XExpeditionConfig.GetCharacterCfgById(eCharaId).Rank or 1
            local baseId = XExpeditionConfig.GetBaseIdByECharId(eCharaId)
            local baseCfg = XExpeditionConfig.GetBaseCharacterCfgById(baseId)
            if baseCfg then
                local gridGo = CS.UnityEngine.Object.Instantiate(self.GridHead)
                gridGo.transform:SetParent(self.PanelTeamContent, false)
                self.TeamHeadIcons[index] = HeadScript.New(gridGo, function() self:OnClickHead() end)
                self.TeamHeadIcons[index]:RefreshData(baseCfg, rank)             
            end
        end
    end
end

function XUiExpeditionDefaultTeamGrid:RefreshData(cfg)
    if not cfg then self.GameObject:SetActiveEx(false) return end
    self.GameObject:SetActiveEx(true)
    self.TeamCfg = cfg
    self.TxtName.text = cfg.Name
end

function XUiExpeditionDefaultTeamGrid:OnClickSelect()
    self.DefaultTeamUi:SetSelect(self.TeamCfg.TeamId)
end

function XUiExpeditionDefaultTeamGrid:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiExpeditionDefaultTeamGrid:OnClickHead()
    XLuaUiManager.Open("UiExpeditionRoleList", self.TeamCfg.TeamId)
end

function XUiExpeditionDefaultTeamGrid:OnClickCombo()
    if not self.PreviewTeam then
        self.PreviewTeam = XTeam.New(self.TeamCfg.TeamId)
        local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
        local robotMaxNum = eActivity:GetRecruitRobotMaxNum()
        self.PreviewTeam:InitTeamPos(robotMaxNum)
        self.PreviewTeam:AddMemberListByECharaIds(self.TeamCfg.ECharacterIds)
    end
    self.PreviewTeam:CheckCombos()
    XLuaUiManager.Open("UiExpeditionComboTips", self.ECombo, self.PreviewTeam)
end

function XUiExpeditionDefaultTeamGrid:CheckTeamIsUnlock(preStageType)
    if not XTool.IsNumberValid(preStageType) then
        return true
    end
    local isAnd = preStageType == XExpeditionConfig.PreStageCheckType.And
    local preStageIds = self.TeamCfg.PreStageIds
    if XTool.IsTableEmpty(preStageIds) then
        return true
    end
    
    local isUnlock = isAnd
    local lockStageId = preStageIds[1] -- 模式选中前置条件的第一个
    for _, stageId in pairs(preStageIds) do
        local passed = XDataCenter.ExpeditionManager.CheckPassedByStageId(stageId)
        if isAnd then
            if not passed then
                lockStageId = stageId
                isUnlock = false
                break
            end
        else
            if passed then
                isUnlock = true
                break
            end
        end
    end
    local name = ""
    if not isUnlock then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(lockStageId)
        name = stageCfg.Name
    end

    return isUnlock, name
end

return XUiExpeditionDefaultTeamGrid