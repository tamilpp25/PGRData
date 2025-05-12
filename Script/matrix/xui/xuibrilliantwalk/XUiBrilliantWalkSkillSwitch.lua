local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--技能切换界面
local XUiBrilliantWalkSkillSwitch = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkSkillSwitch")
local XUIBrilliantWalkStageSkillSwitchGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageSkillSwitchGrid")--必杀模块Grid

function XUiBrilliantWalkSkillSwitch:OnAwake()
    --目标技能的激活状态
    self.ActiveSkill = false
    --SkillGrid列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUIBrilliantWalkStageSkillSwitchGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridSkill.gameObject:SetActiveEx(false) --SkillGridUI template
    --激活目标技能按钮
    self.BtnActive.CallBack = function()
        self:OnBtnActiveTargetSkill()
    end
    --取消激活目标技能按钮
    self.BtnDisactive.CallBack = function()
        self:OnBtnDisactiveTargetSkill()
    end
    --关闭按钮
    self.BtnTanchuangCloseBig.CallBack = function()
        self:OnBtnCancel()
    end
    self.BtnCancel.CallBack = function()
        self:OnBtnCancel()
    end
    --确认按钮
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirm()
    end
end
function XUiBrilliantWalkSkillSwitch:OnEnable(openUiData)
    self:UpdateView(openUiData)
end
--刷新模块信息界面
-- openUiData = {TrenchId,SkillId,PerkId = nil}
function XUiBrilliantWalkSkillSwitch:UpdateView(openUiData)
    self.TrenchId = openUiData.TrenchId
    self.SkillId = openUiData.SkillId
    self.PerkId = openUiData.PerkId
    local perkConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(self.PerkId)
    --设置设置技能 名 描述 图标 激活状态
    if perkConfig.Icon then
        self.ImgIcon:SetRawImage(perkConfig.Icon)
    end
    self.TxtName.text = perkConfig.Name
    self.TxtDesc.text = perkConfig.Desc
    self.ActiveSkill = false
    self.BtnActive.gameObject:SetActiveEx(true)
    self.BtnDisactive.gameObject:SetActiveEx(false)
    --刷新列表
    self.EquipedSkills = XDataCenter.BrilliantWalkManager.GetAllEquipedSkillId() --获取装备了的技能列表
    self.EquipedSkillsUiState = {} --初始化装备了的技能列表 在当前UI的状态 (全为已激活)
    --显示可以卸载的技能
    for i=1,#self.EquipedSkills do
        table.insert(self.EquipedSkillsUiState,true)
    end
    self.DynamicTable:SetDataSource(self.EquipedSkills)
    self.DynamicTable:ReloadDataSync(1)
    --更新能量点数显示
    self.MaxEnergy = XDataCenter.BrilliantWalkManager.GetPluginMaxEnergy()
    self:UpdateEnergy()
end
--更新能量点数显示
function XUiBrilliantWalkSkillSwitch:UpdateEnergy()
    local equipedPlugin = {}
    for i=1,#self.EquipedSkills do
        if self.EquipedSkillsUiState[i] then
            local trenchId = self.EquipedSkills[i][1]
            local skillId = self.EquipedSkills[i][2]
            table.insert(equipedPlugin,skillId)
            local perkId = XDataCenter.BrilliantWalkManager.GetPluginInstallInfo(trenchId,skillId)
            if perkId == 0 then
                XLog.Error("Skill:" .. skillId .. " Doesnt Equiped Perk")
            else
                table.insert(equipedPlugin,perkId)
            end
        end
    end
    self.CurEnergy = XDataCenter.BrilliantWalkManager.GetCustomPluginEnergy(equipedPlugin)
    if self.ActiveSkill then
        self.CurEnergy = self.CurEnergy + XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.SkillId) + XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.PerkId)
    end
    self.MaxEnergy = XDataCenter.BrilliantWalkManager.GetPluginMaxEnergy()
    self.TextPoint.text = self.CurEnergy .. "/" .. self.MaxEnergy
end
--刷新滚动页面
function XUiBrilliantWalkSkillSwitch:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateView(self,self.EquipedSkills[index])
        grid:SetSkillActive(self.EquipedSkillsUiState[index])
    end
end
--点击激活目标技能
function XUiBrilliantWalkSkillSwitch:OnBtnActiveTargetSkill()
    self.ActiveSkill = true
    self.BtnActive.gameObject:SetActiveEx(false)
    self.BtnDisactive.gameObject:SetActiveEx(true)
    self:UpdateEnergy()
end
function XUiBrilliantWalkSkillSwitch:OnBtnDisactiveTargetSkill()
    self.ActiveSkill = false
    self.BtnActive.gameObject:SetActiveEx(true)
    self.BtnDisactive.gameObject:SetActiveEx(false)
    self:UpdateEnergy()
end
--点击取消激活目标技能
--点击激活技能
function XUiBrilliantWalkSkillSwitch:OnBtnActiveSkill(skillGrid)
    skillGrid:SetSkillActive(true)
    for i=1,#self.EquipedSkills do
        if self.EquipedSkills[i][1] == skillGrid.TrenchId and self.EquipedSkills[i][2] == skillGrid.SkillId then
            self.EquipedSkillsUiState[i] = true
        end
    end
    self:UpdateEnergy()
end
--点击取消激活技能
function XUiBrilliantWalkSkillSwitch:OnBtnDisactiveSkill(skillGrid)
    skillGrid:SetSkillActive(false)
    for i=1,#self.EquipedSkills do
        if self.EquipedSkills[i][1] == skillGrid.TrenchId and self.EquipedSkills[i][2] == skillGrid.SkillId then
            self.EquipedSkillsUiState[i] = false
        end
    end
    self:UpdateEnergy()
end 
--点击确认
function XUiBrilliantWalkSkillSwitch:OnBtnConfirm()
    --检查能量
    if self.CurEnergy > self.MaxEnergy then
        XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkStageNotEnoughEnergy"))
        return
    end
    --查看是否有取消操作
    local isCancel
    for i=1,#self.EquipedSkills do
        if self.EquipedSkillsUiState[i] == false then
            isCancel = true
            break;
        end
    end
    self:DoActiveSkill()
end
--实操激活技能操作
function XUiBrilliantWalkSkillSwitch:DoActiveSkill()
    --如果激活的技能是依赖其他插件的技能
    if self.ActiveSkill then
        local needPlugins = XBrilliantWalkConfigs.GetTrenchNeedBuildPlugin(self.TrenchId)
        if #needPlugins > 0 then
            for _,needEquipedPluginId in ipairs(needPlugins) do
                local checkPluginId
                local type = XBrilliantWalkConfigs.GetBuildPluginType(needEquipedPluginId)
                if type == XBrilliantWalkBuildPluginType.Skill then
                    checkPluginId = needEquipedPluginId
                elseif type == XBrilliantWalkBuildPluginType.Perk then
                    checkPluginId = XBrilliantWalkConfigs.GetBuildPluginPrePluginId(needEquipedPluginId)
                end
                if checkPluginId then
                    for i=1,#self.EquipedSkills do
                        --依赖的技能没启动时
                        if self.EquipedSkills[i][2] == checkPluginId and self.EquipedSkillsUiState[i] == false then
                            local trenchName = XBrilliantWalkConfigs.GetTrenchName(self.TrenchId)
                            local pluginName = XBrilliantWalkConfigs.GetBuildPluginName(checkPluginId)
                            XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkQuickChangeWarning",trenchName,pluginName))
                            return
                        end
                    end
                end
            end
        end
    end
    --取消激活选中技能
    for i=1,#self.EquipedSkills do
        if self.EquipedSkillsUiState[i] == false then
            XDataCenter.BrilliantWalkManager.DoDisableSkill(self.EquipedSkills[i][1],self.EquipedSkills[i][2])
        end
    end
    --激活目标技能
    local result = false
    if self.ActiveSkill then
        if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId, self.SkillId) then
            XDataCenter.BrilliantWalkManager.DoDisableSkill(self.TrenchId,self.SkillId)
        end
        result = XDataCenter.BrilliantWalkManager.DoEnableSkillPerk(self.TrenchId,self.SkillId,self.PerkId)
    end
    self.ParentUi:CloseStackTopUi()
    if result then XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_UIEFFECT_CHANGEPLUGIN) end
end
--点击取消/关闭
function XUiBrilliantWalkSkillSwitch:OnBtnCancel()
    --查看是否有取消操作
    local isCancel
    for i=1,#self.EquipedSkills do
        if self.EquipedSkillsUiState[i] == false then
            isCancel = true
            break;
        end
    end
    --出现修改询问是否修改激活技能
    if self.ActiveSkill or isCancel then
        XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"), 
            CS.XTextManager.GetText("BrilliantWalkCancelChangeWarning"),
            XUiManager.DialogType.Normal,
            nil,
            function()
                self.ParentUi:CloseStackTopUi()
            end
        )
    else
        self.ParentUi:CloseStackTopUi()
    end
end