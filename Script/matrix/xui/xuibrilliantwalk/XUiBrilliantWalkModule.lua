--修改安装模块 技能的界面
local XUiBrilliantWalkModule = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkModule")
local XUIBrilliantWalkModulePanelModule = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkModulePanelModule")--模块子界面
local XUIBrilliantWalkModulePanelSkill = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkModulePanelSkill")--技能子界面
local XUIBrilliantWalkModulePanelUltimateModule = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkModulePanelUltimateModule")--必杀模块子界面

local MODULE_LOCK_RIMG = CS.XGame.ClientConfig:GetString("BrilliantWalkStageDefaultModuleLockRImg") --插槽未解锁时图标
local MODULE_UNACTIVE_RIMG = CS.XGame.ClientConfig:GetString("BrilliantWalkStageDefaultModuleUnActiveRImg") --插槽没装备模块时的默认图标

function XUiBrilliantWalkModule:OnAwake()
    --界面左边 四个槽位Panel
    self.UIPanelEquipmentTap = XTool.InitUiObjectByUi({},self.PanelEquipmentTap)
    self.TrenchTapToggleGroup = {}
    local index = 1
    while self.UIPanelEquipmentTap["BtnTog" .. index] do
        local trenchId = index
        local btnTog = self.UIPanelEquipmentTap["BtnTog" .. trenchId]
        table.insert(self.TrenchTapToggleGroup, btnTog)
        btnTog.CallBack = function() self:OnBtnTrenchsClick(trenchId) end
        index = index + 1
    end
    --界面右边普通模块界面
    self.UIPanelEquipmentModule = XUIBrilliantWalkModulePanelModule.New(self.PanelEquipmentModule,self)
    --界面右边必杀模块界面
    self.UIPanelEquipmentUltimateModule = XUIBrilliantWalkModulePanelUltimateModule.New(self.PanelEquipmentUltimateModule,self)
    --界面右边技能子界面
    self.UIPanelEquipmentSkill = XUIBrilliantWalkModulePanelSkill.New(self.PanelEquipmentSkill,self)
    --主界面按钮
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    --返回按钮
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    --帮助按钮
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end
function XUiBrilliantWalkModule:OnStart()
end
--记录并在UI中修改openUIData是因为 此界面记录的插槽和模块会随着玩家操作改变，当从子界面返回时，Main堆栈所记录的打开数据就与操作后的不符。
function XUiBrilliantWalkModule:OnEnable(openUIData)
    self.OpenUIData = openUIData
    self.TrenchId = openUIData.TrenchId
    self.ModuleId = openUIData.ModuleId or self.ModuleId or nil
    self:UpdateView()
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_CHANGE,self.UpdatePanelEquipmentTap,self)
    self.RedPointID = XRedPointManager.AddRedPointEvent(self, self.UpdateTrenchRed, self,{ XRedPointConditions.Types.CONDITION_BRILLIANTWALK_PLUGIN }, -1)
end
function XUiBrilliantWalkModule:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_PLUGIN_CHANGE, self.UpdatePanelEquipmentTap, self)
    XRedPointManager.RemoveRedPointEvent(self.RedPointID)
end
--刷新模块信息界面
function XUiBrilliantWalkModule:UpdateView()
    local UiData = XDataCenter.BrilliantWalkManager.GetUiDataModuleInfo()
    self:UpdatePanelEquipmentTap(UiData)
    if self.TrenchId then
        self.ParentUi:SwitchSceneCamera(XBrilliantWalkCameraType["Trench" .. self.TrenchId])
        local trenchType = XBrilliantWalkConfigs.GetTrenchConfig(self.TrenchId).TrenchType
        if trenchType == XBrilliantWalkTrenchType.Ultimate then --打开右面板必杀模块界面
            self:OpenPanelEquipmentUltimateModule(self.TrenchId)
        else 
            if not self.ModuleId then
                --打开右面板模块界面
                self:OpenPanelEquipmentModule(self.TrenchId)
            else --打开右面板技能界面
                self:OpenPanelEquipmentSkill(self.TrenchId,self.ModuleId)
            end
        end
        
    else --不打开右面板
        self:CloseAllSubPanel()
    end
end

--===========打开界面 begin==========
--打开右插件模块面板
function XUiBrilliantWalkModule:OpenPanelEquipmentModule(trenchId)
    self.PanelEquipmentSkill.gameObject:SetActiveEx(false)
    self.PanelEquipmentModule.gameObject:SetActiveEx(true)
    self.PanelEquipmentUltimateModule.gameObject:SetActiveEx(false)
    self:UpdatePanelEquipmentModule(trenchId)
end
--打开右插件必杀模块面板
function XUiBrilliantWalkModule:OpenPanelEquipmentUltimateModule(trenchId)
    self.PanelEquipmentSkill.gameObject:SetActiveEx(false)
    self.PanelEquipmentModule.gameObject:SetActiveEx(false)
    self.PanelEquipmentUltimateModule.gameObject:SetActiveEx(true)
    self:UpdatePanelEquipmentUltimateModule(trenchId)
end
--打开右插件技能面板
function XUiBrilliantWalkModule:OpenPanelEquipmentSkill(trenchId, moduleId)
    self.PanelEquipmentSkill.gameObject:SetActiveEx(true)
    self.PanelEquipmentModule.gameObject:SetActiveEx(false)
    self.PanelEquipmentUltimateModule.gameObject:SetActiveEx(false)
    self:UpdatePanelEquipmentSkill(trenchId,moduleId)
end
--关闭所有子面板
function XUiBrilliantWalkModule:CloseAllSubPanel()
    self.PanelEquipmentModule.gameObject:SetActiveEx(false)
    self.PanelEquipmentUltimateModule.gameObject:SetActiveEx(false)
    self.PanelEquipmentSkill.gameObject:SetActiveEx(false)
end
--===========打开界面 end==========

--===========刷新界面 begin==========
--刷新左插槽面板
function XUiBrilliantWalkModule:UpdatePanelEquipmentTap(UiData)
    local UiData = UiData or XDataCenter.BrilliantWalkManager.GetUiDataModuleInfo()
    for index,ToggleTrench in pairs(self.TrenchTapToggleGroup) do
        repeat --为了让break变成continue功能做的
            --检查是否存在插槽数据
            if not UiData.TrenchConfigs[index] then
                ToggleTrench.gameObject:SetActiveEx(false)
                break --continue
            end
            ToggleTrench.gameObject:SetActiveEx(true)
            --插槽模块详情
            local pluginId = XDataCenter.BrilliantWalkManager.CheckTrenchEquipModule(index)
            if pluginId then --有装备模块
                local pluginConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
                if pluginConfig.Icon then
                    ToggleTrench:SetRawImage(pluginConfig.Icon)
                end
            else --无装备模块
                ToggleTrench:SetRawImage(MODULE_UNACTIVE_RIMG)
            end
            --是否选中高亮插槽
            if index == self.TrenchId then
                ToggleTrench:SetButtonState(CS.UiButtonState.Select)
            else
                ToggleTrench:SetButtonState(CS.UiButtonState.Normal)
            end
            --检查是否选中该插槽
            if self.TrenchId == index then
                ToggleTrench:SetButtonState(CS.UiButtonState.Select)
            else
                ToggleTrench:SetButtonState(CS.UiButtonState.Normal)
            end
            --检查插槽是否解锁
            if XDataCenter.BrilliantWalkManager.CheckTrenchUnlock(index) then --解锁
                if index == 4 then  --特殊武装模块 配置和UI过于特殊无共性 暂时代码写死
                    ToggleTrench.gameObject:SetActiveEx(true) 
                end
                ToggleTrench:SetDisable(false)
                if self.TrenchId == index then
                    ToggleTrench:SetButtonState(CS.UiButtonState.Select)
                else
                    ToggleTrench:SetButtonState(CS.UiButtonState.Normal)
                end
            else--未解锁
                if index == 4 then  --特殊武装模块 配置和UI过于特殊无共性 暂时代码写死
                    ToggleTrench.gameObject:SetActiveEx(false)
                end
                ToggleTrench:SetDisable(true)
                ToggleTrench:SetRawImage(MODULE_LOCK_RIMG)
            end
            index = index + 1
            break;
        until true
    end
end
--刷新刷右插件模块面板
function XUiBrilliantWalkModule:UpdatePanelEquipmentModule(trenchId)
    self.UIPanelEquipmentModule:UpdateView(trenchId)
end
--刷新刷右插件必杀模块面板
function XUiBrilliantWalkModule:UpdatePanelEquipmentUltimateModule(trenchId)
    self.UIPanelEquipmentUltimateModule:UpdateView(trenchId)
end
--刷新刷右插件技能面板
function XUiBrilliantWalkModule:UpdatePanelEquipmentSkill(trenchId, moduleId)
    self.UIPanelEquipmentSkill:UpdateView(trenchId, moduleId)
end
--===========刷新界面 end==========

--=========红点 begin===========
--插槽红点
function  XUiBrilliantWalkModule:UpdateTrenchRed()
    for index,ToggleTrench in pairs(self.TrenchTapToggleGroup) do
        ToggleTrench:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkTrenchIsRed(index))
    end
end
--=========红点 end=============

--点击插槽按钮
function XUiBrilliantWalkModule:OnBtnTrenchsClick(trenchId)
    if XDataCenter.BrilliantWalkManager.CheckTrenchUnlock(trenchId) then
        --改变当前UI显示数据
        self.TrenchId = trenchId
        self.ModuleId = nil
        self:UpdateView(trenchId)
        --改变主界面堆栈记录UI数据
        self.OpenUIData.TrenchId = trenchId
        self.OpenUIData.ModuleId = nil
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkTrenchNotUnlock"))
    end
end
--点击模块按钮(右侧模块面板)
function XUiBrilliantWalkModule:OnBtnModuleClick(moduleId)
    self.ModuleId = moduleId
    self:OpenPanelEquipmentSkill(self.TrenchId,moduleId)
    --改变主界面堆栈记录UI数据
    self.OpenUIData.ModuleId = moduleId
end
--点击启用模块按钮(右侧技能面板或必杀模块面板)
function XUiBrilliantWalkModule:OnBtnActiveModule(moduleId)
    local result = XDataCenter.BrilliantWalkManager.DoEnableModule(self.TrenchId, moduleId)
    if result then XEventManager.DispatchEvent(XEventId.EVENT_BRILLIANT_WALK_UIEFFECT_CHANGEPLUGIN) end
    return result
end
--点击取消模块按钮(右侧技能面板或必杀模块面板)
function XUiBrilliantWalkModule:OnBtnDisactiveModule(moduleId)
    --XLog.Log("XUiBrilliantWalkModule:OnBtnDisactiveModule T:" .. self.TrenchId .. "  M:" .. moduleId)
    return XDataCenter.BrilliantWalkManager.DoDisableModule(self.TrenchId, moduleId)
end
--点击技能模块按钮(右侧技能面板)
function XUiBrilliantWalkModule:OnBtnActiveSkill(skillId)
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkPerk",{
        TrenchId = self.TrenchId,
        ModuleId = self.ModuleId,
        SkillId = skillId
    })
end
--点击取消激活技能按钮(右侧技能面板)
function XUiBrilliantWalkModule:OnBtnDisactiveSkill(skillId)
    --XLog.Log("XUiBrilliantWalkModule:OnBtnDisactiveSkill T:" .. self.TrenchId .. "  S:" .. skillId)
    return XDataCenter.BrilliantWalkManager.DoDisableSkill(self.TrenchId, skillId)
end

--点击返回按钮
function XUiBrilliantWalkModule:OnBtnBackClick()
    if self.ModuleId then
        self:OnBtnTrenchsClick(self.TrenchId)
        return
    end
    self.TrenchId = nil
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkModule:OnBtnMainUiClick()
    self.TrenchId = nil
    self.ModuleId = nil
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkModule:OnBtnHelpClick()
    XUiManager.ShowHelpTip("BrilliantWalk")
end
