----模块界面XUIBrilliantWalkModule 的子界面PanelModule 选择模块技能界面 的技能Grid
local XUIBrilliantWalkStageSkillPanelSkillGrid = XClass(nil, "XUIBrilliantWalkStageSkillPanelSkillGrid")

local DEFAULT_PERK_RIMG = CS.XGame.ClientConfig:GetString("BrilliantWalkStageDefaultPerkRImg") --技能无装备perk时的默认图标

function XUIBrilliantWalkStageSkillPanelSkillGrid:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    --技能图标按钮
    self.PanelSkill.CallBack = function()
        self:OnBtnActive()
    end
    --Perk图标按钮
    self.PanelPerk.CallBack = function()
        self:OnBtnActive()
    end
    --激活按钮
    self.BtnActive.CallBack = function()
        self:OnBtnActive()
    end
    --取消激活按钮
    self.BtnDisactive.CallBack = function()
        self:OnBtnDisactive()
    end
end

function XUIBrilliantWalkStageSkillPanelSkillGrid:UpdateView(trenchId, pluginId)
    --如果无id 隐藏Grid
    if not pluginId then
        self.PanelUnlock.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(false)
        return
    end
    --如果没解锁 显示上锁状态
    if not XDataCenter.BrilliantWalkManager.CheckPluginUnlock(pluginId) then
        self.PanelUnlock.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(true)
        return
    end
    self.PanelUnlock.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.SkillId = pluginId
    self.TrenchId = trenchId
    local skillConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(self.SkillId)
    --设置图标
    if skillConfig.Icon then
        self.PanelSkill:SetRawImage(skillConfig.Icon)
    end
    --设置技能名
    self.PanelSkill:SetNameByGroup(0,skillConfig.Name)
    --红点
    self.BtnActive:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(pluginId))
    local isPrekRed = false
    local perkList = XBrilliantWalkConfigs.ListPerkListInSkill[pluginId] or {}
    for _,perkList in ipairs(perkList) do
        if XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginIsRed(perkList) then
            isPrekRed = true
            break;
        end
    end
    self.PanelPerk:ShowReddot(isPrekRed)
    --检查是否被激活的技能
    local SkillActive = XDataCenter.BrilliantWalkManager.CheckPluginEquipedInTrench(self.TrenchId,self.SkillId)
    self.PanelSkillActivate.gameObject:SetActiveEx(true)
    self.PanelSkillDisActive.gameObject:SetActiveEx(false)
    self.PanelPerkActivate.gameObject:SetActiveEx(SkillActive)
    self.PanelPerkDisActive.gameObject:SetActiveEx(not SkillActive)
    self.BtnActive.gameObject:SetActiveEx(not SkillActive)
    self.BtnDisactive.gameObject:SetActiveEx(SkillActive)
    for _,rimg in pairs(self.PanelPerk.RawImageList) do
        local color = rimg.color
        color.a = 0
        rimg.color = color
    end
    if SkillActive then
        local perk = XDataCenter.BrilliantWalkManager.GetPluginInstallInfo(self.TrenchId,pluginId)
        if perk == 0 then --无安装Perk
            --self.PanelPerk:SetRawImage(DEFAULT_PERK_RIMG)
        else --安装了Perk 设置图标
            local perkConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(perk)
            if perkConfig.Icon then
                self.PanelPerk:SetRawImage(perkConfig.Icon)
                for _,rimg in pairs(self.PanelPerk.RawImageList) do
                    local color = rimg.color
                    color.a = 1
                    rimg.color = color
                end
            end
        end
    else
        --self.PanelPerk:SetRawImage(DEFAULT_PERK_RIMG)
    end
end

--点击激活按钮
function XUIBrilliantWalkStageSkillPanelSkillGrid:OnBtnActive()
    XDataCenter.BrilliantWalkManager.UiViewPlugin(self.SkillId)
    self.RootUi:OnBtnActiveSkill(self.SkillId)
end
--点击取消激活按钮
function XUIBrilliantWalkStageSkillPanelSkillGrid:OnBtnDisactive()
    self.RootUi:OnBtnDisactiveSkill(self.SkillId)
end

return XUIBrilliantWalkStageSkillPanelSkillGrid