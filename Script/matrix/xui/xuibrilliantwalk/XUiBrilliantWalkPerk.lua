--修改技能Perk界面
local XUiBrilliantWalkPerk = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkPerk")
local XUIBrilliantWalkPerkGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkPerkGrid")--必杀模块Grid


function XUiBrilliantWalkPerk:OnAwake()
    --PerkGrid的内存池
    self.PerkGridPool = XStack.New() --PerkGridUI内存池
    self.PerkGridList = XStack.New() --正在使用的PerkGridUI
    self.GridPerk.gameObject:SetActiveEx(false) --PerkGridUI template
    --关闭按钮
    self.BtnClose.CallBack = function()
        self:OnBtnClose()
    end
    --确认按钮
    self.BtnEnter.CallBack = function()
        self:OnBtnEnter()
    end
end
function XUiBrilliantWalkPerk:OnEnable(openUiData)
    self:UpdateView(openUiData)
end
--刷新模块信息界面
-- openUiData = {TrenchId,SkillId}
function XUiBrilliantWalkPerk:UpdateView(openUiData)
    self.TrenchId = openUiData.TrenchId
    self.ModuleId = openUiData.ModuleId
    self.SkillId = openUiData.SkillId
    --设置技能信息
    local skillConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(self.SkillId)
    if skillConfig.Icon then
        self.ImgIcon:SetRawImage(skillConfig.Icon)
    end
    self.TxtName.text = skillConfig.Name
    self.TxtDesc.text = skillConfig.Desc
    --设置当前能量
    self.CurEnergy = XDataCenter.BrilliantWalkManager.GetCurPluginEnergy()
    self.MaxEnergy = XDataCenter.BrilliantWalkManager.GetPluginMaxEnergy()
    self.TxtPoint.text = self.CurEnergy .. "/" .. self.MaxEnergy
    --设置激活所需能量
    if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId, self.SkillId) then --若已经激活则不消耗能量
        self.CurrentPerkId = XDataCenter.BrilliantWalkManager.GetPluginInstallInfo(self.TrenchId,self.SkillId)
    end
    --Perk列表
    self.SelectedGrid = nil
    local selectedGrid = nil
    local perkList = XBrilliantWalkConfigs.ListPerkListInSkill[self.SkillId]
    local perkSet = XDataCenter.BrilliantWalkManager.GetSkillPerkSetData(self.SkillId) or perkList[1]
    self:PerkGridReturnPool()
    for index,perkId in ipairs(perkList) do
        local gird = self:GetPerkGrid()
        gird:UpdateView(perkId,index)
        if perkId == perkSet then
            selectedGrid = gird
            gird:SetSelected(true)
        else
            gird:SetSelected(false)
        end
    end
    if selectedGrid then selectedGrid:OnClickSelect()
        self:UpdateNeedEnergy()
    end
end
--刷新所需能量
function XUiBrilliantWalkPerk:UpdateNeedEnergy()
    --当前已经装备了技能 只是替换Perk
    if self.CurrentPerkId then
        local curPerkNeedEnergy = XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.CurrentPerkId)
        local targetPerkNeedEnergy = XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.SelectedGrid.PerkId)
        self.NeedEnergy = targetPerkNeedEnergy - curPerkNeedEnergy
    else --当前未装备技能
        local skillNeedEnergy = XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.SkillId)
        local targetPerkNeedEnergy = XBrilliantWalkConfigs.GetBuildPluginNeedEnergy(self.SelectedGrid.PerkId)
        self.NeedEnergy = targetPerkNeedEnergy + skillNeedEnergy
    end
    if self.NeedEnergy == 0 then
        self.PanelNeedPoint.gameObject:SetActiveEx(false)
        return
    end
    self.PanelNeedPoint.gameObject:SetActiveEx(true)
    self.TxtATNums.text = self.NeedEnergy
end
--提取必杀模块Grid
function XUiBrilliantWalkPerk:GetPerkGrid()
    local item
    if self.PerkGridPool:IsEmpty() then
        local object = CS.UnityEngine.Object.Instantiate(self.GridPerk)
        object.transform:SetParent(self.PanelContent, false)
        item = XUIBrilliantWalkPerkGrid.New(object,self)
    else
        item = self.PerkGridPool:Pop()
    end
    item.GameObject:SetActiveEx(true)
    self.PerkGridList:Push(item)
    return item
end
--放回必杀模块Grid
function XUiBrilliantWalkPerk:PerkGridReturnPool()
    while (not self.PerkGridList:IsEmpty()) do
        local object = self.PerkGridList:Pop()
        object.GameObject:SetActiveEx(false)
        self.PerkGridPool:Push(object)
    end
end
--点击Perk的选择
function XUiBrilliantWalkPerk:OnGridClick(perkGrid)
    if self.SelectedGrid == perkGrid then
        return
    end
    if self.SelectedGrid then
        self.SelectedGrid:SetSelected(false)
    end
    self.SelectedGrid = perkGrid
    self.SelectedGrid:SetSelected(true)
    self:UpdateNeedEnergy()
end
--点击确认按钮
function XUiBrilliantWalkPerk:OnBtnEnter()
    if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.ModuleId) then
        self:DoActivePlugin()
    else --如果没激活模块
        --提示激活模块
        XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"), 
            CS.XTextManager.GetText("BrilliantWalkStageModuleActiveTipContent"),
            XUiManager.DialogType.Normal,
            nil,
            function()
                local equipedModule = XDataCenter.BrilliantWalkManager.CheckTrenchEquipModule(self.TrenchId)
                if equipedModule then --如果当前插槽已经装备了其他模块
                    local equipedName = XBrilliantWalkConfigs.GetBuildPluginName(equipedModule)
                    local trenchName = XBrilliantWalkConfigs.GetTrenchName(self.TrenchId)
                    --替换模块提示
                    XUiManager.DialogTip(
                        CS.XTextManager.GetText("TipTitle"),
                        CS.XTextManager.GetText("BrilliantWalkModuleActiveWarning",equipedName,trenchName),
                        XUiManager.DialogType.Normal,
                        nil,
                        function()
                            if XDataCenter.BrilliantWalkManager.DoEnableModule(self.TrenchId,self.ModuleId) then
                                self:DoActivePlugin()
                            end                            
                        end)
                else
                    if XDataCenter.BrilliantWalkManager.DoEnableModule(self.TrenchId,self.ModuleId) then
                        self:DoActivePlugin()
                    end                
                end
            end
        )
    end
end
--执行启用模块
function XUiBrilliantWalkPerk:DoActiveModule()
    
end
--确认激活技能
function XUiBrilliantWalkPerk:DoActivePlugin()
    local perkId = nil
    if self.SelectedGrid then
        perkId = self.SelectedGrid.PerkId
    end
    --曾经的需求是可以取消装备Perk的(已废弃) 已经合并技能和Perk的激活接口
    --if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId, self.SkillId) then
    --    if perkId then
    --        XDataCenter.BrilliantWalkManager.DoEnablePerk(self.TrenchId,perkId)
    --        self.ParentUi:CloseStackTopUi()
    --    else
    --        XDataCenter.BrilliantWalkManager.DoDisablePerkBySkillId(self.TrenchId,self.SkillId)
    --        self.ParentUi:CloseStackTopUi()
    --    end
    --end
    --如果能量不足
    if (self.CurEnergy + self.NeedEnergy) > self.MaxEnergy then
        self.ParentUi:CloseStackTopUi()
        self.ParentUi:OpenStackSubUi("UiBrilliantWalkSkillSwitch",{
            TrenchId = self.TrenchId,
            SkillId = self.SkillId,
            PerkId = perkId
        })
    else
        if XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId, self.SkillId) then
            XDataCenter.BrilliantWalkManager.DoDisableSkill(self.TrenchId,self.SkillId)
        end
        local result = XDataCenter.BrilliantWalkManager.DoEnableSkillPerk(self.TrenchId,self.SkillId,perkId)
        self.ParentUi:CloseStackTopUi()
        if result then XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_UIEFFECT_CHANGEPLUGIN) end
    end
end
--点击关闭按钮
function XUiBrilliantWalkPerk:OnBtnClose()
    self.ParentUi:CloseStackTopUi()
end