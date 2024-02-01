local XUiMultiDimPresetRoleTip = XLuaUiManager.Register(XLuaUi, "UiMultiDimPresetRoleTip")
local XUiGuidMultiDimPresetRole = require("XUi/XUiMultiDim/XUiGuidMultiDimPresetRole")
local DefaultShowCharacter = 3

function XUiMultiDimPresetRoleTip:OnAwake()
    self:RegisterUiEvents()
    self.BtnTabGrid = {}
    self.CharacterGrid = {}
    self.CareerId = 0
end

function XUiMultiDimPresetRoleTip:OnStart(stageId)
    self.StageId = stageId
    self.MultiDimCareer = XDataCenter.MultiDimManager.GetMultiDimCareerInfo()
    self:InitBtnTab()
    self:InitCharacterPanel()
end

function XUiMultiDimPresetRoleTip:OnEnable()
    self.PanelTab:SelectIndex(self.CurrentTab or 1)
end

function XUiMultiDimPresetRoleTip:InitBtnTab()
    if not self.MultiDimCareer then
        return
    end
    local tabGroup = {}
    for i = 1, #self.MultiDimCareer do
        local config = self.MultiDimCareer[i]
        local btn = self.BtnTabGrid[i]
        if not btn then
            local go = #self.BtnTabGrid == 0 and self.BtnTabTc or XUiHelper.Instantiate(self.BtnTabTc, self.PanelTab.transform)
            btn = go:GetComponent("XUiButton")
            table.insert(self.BtnTabGrid, btn)
        end
        btn:SetNameByGroup(0, config.Name)
        tabGroup[i] = btn
    end
    for i = #self.MultiDimCareer + 1, #self.BtnTabGrid do
        self.BtnTabGrid[i].GameObject:SetActiveEx(false)
    end
    self.PanelTab:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiMultiDimPresetRoleTip:InitCharacterPanel()
    for i = 1, DefaultShowCharacter do
        local panel = self.CharacterGrid[i]
        if not panel then
            local go = #self.CharacterGrid == 0 and self.PanelRole or XUiHelper.Instantiate(self.PanelRole, self.PanelRoleList)
            panel = XUiGuidMultiDimPresetRole.New(go, self)
            table.insert(self.CharacterGrid, panel)
        end
    end
end

function XUiMultiDimPresetRoleTip:OnClickTabCallBack(tabIndex)
    if self.CurrentTab and self.CurrentTab == tabIndex then
        return
    end

    self.CurrentTab = tabIndex
    local config = self.MultiDimCareer[self.CurrentTab]
    self.CareerId = config.Career
    XDataCenter.MultiDimManager.UpdateDefaultCharacterIds(self.CareerId)
    self:RefreshCharacter()
    -- 播放动画
    self:PlayAnimation("QieHuan")
end

function XUiMultiDimPresetRoleTip:RefreshCharacter()
    local entityIds = XDataCenter.MultiDimManager.GetPresetCharacters(self.CareerId)
    for pos, entityId in pairs(entityIds) do
        local panel = self.CharacterGrid[pos]
        if panel then
            panel:Refresh(entityId, pos)
        end
    end
end

function XUiMultiDimPresetRoleTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBig)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiMultiDimPresetRoleTip:OnBtnTanchuangCloseBig()
    self:Close()
end
-- 保存预设
function XUiMultiDimPresetRoleTip:OnBtnConfirmClick()
    local entityIds = XDataCenter.MultiDimManager.GetPresetCharacters(self.CareerId)
    entityIds = self:CleanEntityIds(entityIds)
    XDataCenter.MultiDimManager.MultiDimSelectCharacterRequest(self.CareerId, entityIds, function()
        XUiManager.TipText("MultiDimPresetRoleSaveSucceed")
        self:Close()
    end)
end
-- 移除value为0的信息，保留原来元素索引
function XUiMultiDimPresetRoleTip:CleanEntityIds(t)
    local n = {}
    for k, v in pairs(t) do
        if XTool.IsNumberValid(v) then
            n[k] = v
        end
    end
    return n
end

-- 打开角色界面
function XUiMultiDimPresetRoleTip:OnBtnRoleClick(pos)
    XLuaUiManager.Open("UiBattleRoomRoleDetail",
            self.StageId,
            XDataCenter.MultiDimManager.GetTeam(self.CareerId),
            pos,
            self:GetRoleDetailProxy())
end

function XUiMultiDimPresetRoleTip:GetRoleDetailProxy()
    return {
        GetEntities = function(proxy, characterType)
            return XDataCenter.MultiDimManager.GetOwnCharacterListByFilterCareer(self.CareerId, characterType)
        end,
        GetAutoCloseInfo = function(proxy)
            return true, XDataCenter.MultiDimManager.GetEndTime(), function(isClose)
                if isClose then
                    XDataCenter.MultiDimManager.HandleActivityEndTime()
                end
            end
        end,
        GetFilterTypeAndSortType = function(proxy)
            return XRoomCharFilterTipsConfigs.EnumFilterType.MultiDim, XRoomCharFilterTipsConfigs.EnumSortType.Common
        end,
        AOPOnStartAfter = function(proxy, rootUi)
            -- 没有独域机体时将按钮隐藏掉
            local isomerRoles = XDataCenter.MultiDimManager.GetOwnCharacterListByFilterCareer(self.CareerId, XEnumConst.CHARACTER.CharacterType.Isomer)
            if XTool.IsTableEmpty(isomerRoles) then
                rootUi.BtnTabShougezhe.gameObject:SetActiveEx(false)
            end
        end,
        AOPSetJoinBtnIsActiveAfter = function(proxy, rootUi)
            -- 卸下队伍 默认没有卸下队伍按钮
            rootUi.BtnQuitTeam.gameObject:SetActiveEx(false)
        end,
        AOPOnBtnJoinTeamClickedAfter = function(proxy, rootUi)
            self:RefreshCharacter()
        end
    }
end

return XUiMultiDimPresetRoleTip