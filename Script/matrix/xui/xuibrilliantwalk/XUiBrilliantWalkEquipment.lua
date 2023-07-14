--整备界面 也是出击准备界面
local XUiBrilliantWalkEquipment = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkEquipment")
local DEFAULT_MODULE_RIMG = CS.XGame.ClientConfig:GetString("BrilliantWalkStageDefaultModuleRImg") --插槽没装备模块时的默认图标

function XUiBrilliantWalkEquipment:OnAwake()
    self.UIPanelEquipment = XTool.InitUiObjectByUi({},self.PanelEquipment)
    --插槽按钮
    local index = 1
    self.Tranchs = {}
    while self.UIPanelEquipment["GridModelTrench" .. index] do
        local trenchId = index
        local btn = self.UIPanelEquipment["GridModelTrench" .. index]
        self.Tranchs[index] = XTool.InitUiObjectByUi({},btn)
        self.Tranchs[index].Button = btn
        --解锁 已激活模块
        self.Tranchs[index].PanelActive.CallBack = function()
            self:OnTrenchClick(trenchId)
        end
        --解锁 未激活模块
        self.Tranchs[index].PanelDisActive.CallBack = function()
            self:OnTrenchClick(trenchId)
        end
        --未解锁
        self.Tranchs[index].PanelDisable.CallBack = function()
            self:OnLockTrenchClick(trenchId)
        end
        index = index + 1
    end
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
    --出击按钮
    self.BtnEnterFight.CallBack = function()
        self:OnGameStartClick()
    end
    --被动技能
    self.PanelAdditionalBuff.CallBack = function()
        self:OnAddtionalBuffClick()
    end
end
function XUiBrilliantWalkEquipment:OnEnable(openUIData)
    self.StageId = (openUIData and openUIData.StageId) or nil
    self:UpdateView()
    self.ParentUi:SwitchSceneCamera(XBrilliantWalkCameraType.Equipment)
end
--刷新界面
function XUiBrilliantWalkEquipment:UpdateView()
    local uiData = XDataCenter.BrilliantWalkManager.GetUiDataEquipment(self.StageId)
    if uiData.StageConfig then --准备出击界面
        self.BtnEnterFight.gameObject:SetActiveEx(true) --显示进入战斗按钮
        --判断关卡模块类型 显示不同UI
        if uiData.StageConfig.Type == XBrilliantWalkStageModuleType.Custom then
            self.PanelEquipment.gameObject:SetActiveEx(true) --显示插槽界面
            self.PanelProhibit.gameObject:SetActiveEx(false) --关闭无法选择模块UI 
            self:UpdateTrenchView(uiData) --更新插槽界面
        elseif uiData.StageConfig.Type == XBrilliantWalkStageModuleType.Inherent then
            self.PanelEquipment.gameObject:SetActiveEx(false) --关闭插槽界面
            self.PanelProhibit.gameObject:SetActiveEx(true) --显示无法选择模块UI 
        else --填写错误的关卡
            XLog.Error("BrilliantWalk StageConfig ModuleType Error StageId:" .. self.StageId .. "  ModuleType:" .. uiData.StageConfig.Type)
            self.PanelEquipment.gameObject:SetActiveEx(false) --关闭插槽界面
            self.PanelProhibit.gameObject:SetActiveEx(true) --显示无法选择模块UI 
            self.BtnEnterFight.gameObject:SetActiveEx(false)
        end
    else --普通整备界面
        self.PanelEquipment.gameObject:SetActiveEx(true) --显示插槽界面
        self:UpdateTrenchView(uiData) --更新插槽界面
        self.PanelProhibit.gameObject:SetActiveEx(false) --显示无法选择模块UI 
        self.BtnEnterFight.gameObject:SetActiveEx(false) --关闭进入战斗按钮
    end
    self:UpdateAdditionalBuffView(uiData) --更新被动技能界面
end
--刷新模块整备插槽界面
function XUiBrilliantWalkEquipment:UpdateTrenchView(uiData)
    uiData = uiData or XDataCenter.BrilliantWalkManager.GetUiDataEquipment(self.StageId)
    local index = 1
    while self.Tranchs[index] do
        repeat --为了让break变成continue功能做的
            local BtnTrench = self.Tranchs[index].Button
            --检查是否存在插槽数据
            if not uiData.TrenchConfigs[index] then
                BtnTrench.gameObject:SetActiveEx(false)
                break --continue
            end
            BtnTrench.gameObject:SetActiveEx(true)
            --检查插槽是否解锁
            if XDataCenter.BrilliantWalkManager.CheckTrenchUnlock(index) then --解锁
                if index == 4 then
                    self.UIPanelEquipment.PanelTrench2.gameObject:SetActiveEx(true)
                end
                self.Tranchs[index].PanelDisable.gameObject:SetActiveEx(false)
                --红点显示
                BtnTrench:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkTrenchIsRed(index))
                --插槽是否装备模块
                local pluginId = XDataCenter.BrilliantWalkManager.CheckTrenchEquipModule(index)
                if pluginId then --有装备模块
                    local pluginConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
                    BtnTrench:SetNameByGroup(0,pluginConfig.Name)
                    if pluginConfig.Icon then
                        BtnTrench:SetRawImage(pluginConfig.Icon)
                    end
                    self.Tranchs[index].PanelActive.gameObject:SetActiveEx(true)
                    self.Tranchs[index].PanelDisActive.gameObject:SetActiveEx(false)
                else --无装备模块
                    BtnTrench:SetNameByGroup(0,"")
                    self.Tranchs[index].PanelActive.gameObject:SetActiveEx(false)
                    self.Tranchs[index].PanelDisActive.gameObject:SetActiveEx(true)
                end
            else --未解锁
                BtnTrench:ShowReddot(false)
                if index == 4 then
                    self.UIPanelEquipment.PanelTrench2.gameObject:SetActiveEx(false)
                else
                    self.Tranchs[index].PanelDisActive.gameObject:SetActiveEx(false)
                    self.Tranchs[index].PanelActive.gameObject:SetActiveEx(false)
                    self.Tranchs[index].PanelDisable.gameObject:SetActiveEx(true)
                end
            end
            
            index = index + 1
            break;
        until true
    end
end
--刷新被动技能界面
function XUiBrilliantWalkEquipment:UpdateAdditionalBuffView(uiData)
    uiData = uiData or XDataCenter.BrilliantWalkManager.GetUiDataEquipment(self.StageId)
    local index = 1
    --设置每个被动BUFF图标
    while self.UIPanelEquipment["BuffIcon"..index] do
        local ImgIcon = self.UIPanelEquipment["BuffIcon"..index]
        local data = uiData.AddtionalBuffs[index]
        if data then
            if data.Icon then
                self:SetUiSprite(ImgIcon, data.Icon)
            end
            ImgIcon.gameObject:SetActiveEx(true)
        else
            ImgIcon.gameObject:SetActiveEx(false)
        end
        index = index + 1
    end
end
--点击模块插槽
function XUiBrilliantWalkEquipment:OnTrenchClick(trenchIndex)
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkModule",{
        TrenchId = trenchIndex
    })
end
--点击锁定的模块插槽
function XUiBrilliantWalkEquipment:OnLockTrenchClick()
    XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkTrenchNotUnlock"))
end
--点击出击按钮
function XUiBrilliantWalkEquipment:OnGameStartClick()
    XDataCenter.BrilliantWalkManager.EnterStage(self.StageId,function(cb)
        self.ParentUi:PlaySallyAnime(cb)
    end)
end
--点击被动技能
function XUiBrilliantWalkEquipment:OnAddtionalBuffClick()
    self.ParentUi:OpenMiniSubUI("UiBrilliantWalkAdditionalBuff")
end
--点击返回按钮
function XUiBrilliantWalkEquipment:OnBtnBackClick()
    self.StageId = nil
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkEquipment:OnBtnMainUiClick()
    self.StageId = nil
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkEquipment:OnBtnHelpClick()
    XUiManager.ShowHelpTip("BrilliantWalk")
end