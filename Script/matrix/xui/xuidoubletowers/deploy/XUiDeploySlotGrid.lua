local XUiDeploySlotGrid = XClass(nil, "XUiDeploySlotGrid")

--动作塔防养成界面的插槽格子
function XUiDeploySlotGrid:Ctor(ui, index, isOpenDeploy, moduleType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Index = index  --插槽下标
    self.IsOpenDeploy = isOpenDeploy    --是否跳转到养成界面
    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.ModuleType = moduleType
    self:InitUi()
    self:AutoAddListener()
end

function XUiDeploySlotGrid:InitUi()
    self.Icon = XUiHelper.TryGetComponent(self.Transform, "Partner/PartnerIcon", "RawImage")
    self.BtnDetail = XUiHelper.TryGetComponent(self.Transform, "Partner/BtnCarryPartner", "XUiButton")
    self.Name = XUiHelper.TryGetComponent(self.Transform, "Partner/Nomal", "Text")
    self.PanelNoPartner = XUiHelper.TryGetComponent(self.Transform, "Partner/PanelNoPartner")
    self.ImgLevelBg = XUiHelper.TryGetComponent(self.Transform, "Partner/ImgLevelBg")
    self.TxtSubSkillLevel = XUiHelper.TryGetComponent(self.Transform, "Partner/ImgLevelBg/RawImage/TxtSubSkillLevel", "Text")
    self.Selected = XUiHelper.TryGetComponent(self.Transform, "Partner/Selected")
    self.BtnLock = XUiHelper.TryGetComponent(self.Transform, "BtnLock", "XUiButton")
    self.TxtLock = XUiHelper.TryGetComponent(self.Transform, "BtnLock/TextLock", "Text")
    self.RedPoint = XUiHelper.TryGetComponent(self.Transform, "Partner/Red")

    if self.TxtLock then
        self.TxtLock.gameObject:SetActiveEx(true)
    end
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(false)
    end
    self.Selected.gameObject:SetActiveEx(false)
end

function XUiDeploySlotGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
end

function XUiDeploySlotGrid:Refresh(pluginId)
    self.PluginId = pluginId
    local index = self.Index
    --local pluginId = self.TeamDb:GetRolePluginId(index)
    local preStageId = XDoubleTowersConfigs.GetSlotPreStageId(index, self.ModuleType)
    local isUnLock = not XTool.IsNumberValid(preStageId) and true or self.BaseInfo:IsStagePassed(preStageId)
    if self.Name then
        self.Name.gameObject:SetActiveEx(isUnLock)
    end
    
    if self.BtnLock then
        self.BtnLock.gameObject:SetActiveEx(not isUnLock)
    end
    if not isUnLock then
        self:SetShowPlugin(false)
        if self.TxtLock then
            local stageName = XDoubleTowersConfigs.GetStageName(preStageId) or ""
            local text = XUiHelper.GetText("DoubleTowersStageLockCondition", stageName)
            self.TxtLock.text = text
        end
        return
    end
    
    --红点检测
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS_SLOT_UNLOCKED }, {
        ModuleType = self.ModuleType,
        Index = self.Index
    })

    if not self:IsHavePlugin() then
        self:SetShowPlugin(false)
        return
    end
    
    local pluginLevelId = self.BaseInfo:GetPluginLevelId(pluginId)
    if not XTool.IsNumberValid(pluginLevelId) then
        self:SetShowPlugin(false)
        return
    end
    --图标
    local icon = XDoubleTowersConfigs.GetPluginIcon(pluginId)
    if self.Icon then
        self.Icon:SetRawImage(icon)
    end
    --名字
    if self.Name then
        self.Name.text = XDoubleTowersConfigs.GetPluginLevelName(pluginLevelId)
    end
    --等级
    if self.TxtSubSkillLevel then
        self.TxtSubSkillLevel.text = XDoubleTowersConfigs.GetPluginLevel(pluginLevelId)
    end

    self:SetShowPlugin(true)
end

function XUiDeploySlotGrid:SetShowPlugin(isShow)
    if self.PanelNoPartner then
        self.PanelNoPartner.gameObject:SetActiveEx(not isShow)
    end
    if self.ImgLevelBg then
        self.ImgLevelBg.gameObject:SetActiveEx(isShow)
    end
    if self.Name then
        --self.Name.gameObject:SetActiveEx(isShow)
        if not isShow then
            self.Name.text = XUiHelper.GetText("EquipEnable")
        end
    end
    if self.Icon then
        self.Icon.gameObject:SetActiveEx(isShow)
    end
end

function XUiDeploySlotGrid:SetSelect(isSelect)
    self.Selected.gameObject:SetActiveEx(isSelect)
end

function XUiDeploySlotGrid:SetSelectCb(selectCb)
    self.OnSelect = selectCb
end

function XUiDeploySlotGrid:SetSlotChangeCb(slotChangeCb)
    self.OnSlotChange = slotChangeCb
end

function XUiDeploySlotGrid:OnBtnDetailClick()
    if self.OnSelect then
        self.OnSelect(self)
    end
    if self.RedPoint then
        XDataCenter.DoubleTowersManager.RefreshUnlockSlotByModuleType(self.ModuleType, self.Index)
        --红点检测
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS_SLOT_UNLOCKED }, {
            ModuleType = self.ModuleType,
            Index = self.Index
        })
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_SLOT_UNLOCK)
    end
    if self.IsOpenDeploy then
        local moduleType = XDoubleTowersConfigs.GetPluginType(self.PluginId)
        XLuaUiManager.Open("UiDoubleTowersDeploy", moduleType)
        return
    end

    if not self:IsHavePlugin() then
        return
    end
    XLuaUiManager.Open("UiDoubleTowersSkillDetails", self.PluginId, handler(self, self.OnSlotChange))
end

function XUiDeploySlotGrid:IsHavePlugin()
    --local index = self.Index
    --local pluginId = self.TeamDb:GetRolePluginId(index)
    return XTool.IsNumberValid(self.PluginId)
end

function XUiDeploySlotGrid:OnCheckRedPoint(count)
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(count >= 0)
    end
end

return XUiDeploySlotGrid