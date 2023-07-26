----模块界面XUIBrilliantWalkModule 的子界面PanelModule 选择模块技能界面 的技能Grid
local XUIBrilliantWalkStageSkillSwitchGrid = XClass(nil, "XUIBrilliantWalkStageSkillSwitchGrid")

local DEFAULT_PERK_RIMG = CS.XGame.ClientConfig:GetString("BrilliantWalkStageDefaultPerkRImg") --技能无装备perk时的默认图标

function XUIBrilliantWalkStageSkillSwitchGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    --激活按钮
    self.BtnActive.CallBack = function()
        self:OnBtnActive()
    end
    --取消激活按钮
    self.BtnDisactive.CallBack = function()
        self:OnBtnDisactive()
    end
end

--刷新界面
--plugInData = {trenchId,pluginId}
function XUIBrilliantWalkStageSkillSwitchGrid:UpdateView(rootUI, plugInData)
    self.RootUi = rootUI
    self.TrenchId = plugInData[1]
    self.SkillId = plugInData[2]
    local perkId = XDataCenter.BrilliantWalkManager.GetPluginInstallInfo(self.TrenchId,self.SkillId)
    if (not perkId) or perkId == 0 then
        XLog.Error("SkillId:" .. self.SkillId .. " Dosent Equip Perk!")
        return
    end
    local perkConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(perkId)
    --设置设置技能 名 描述 图标
    if perkConfig.Icon then
        self.ImgSkillIcon:SetRawImage(perkConfig.Icon)
    end
    self.TxtName.text = perkConfig.Name
    self.TxtDesc.text = perkConfig.Desc

	--已废弃 已激活技能必定装备Perk
    --if perkId == 0 then --无装备Perk
    --    self.ImgPerkIcon.color = CS.UnityEngine.Color(1,1,1,0)
    --else --安装了Perk 设置图标
    --    local perkConfig = XBrilliantWalkConfigs.GetBuildPluginConfig(perkId)
    --    if perkConfig.Icon then
    --        self.ImgPerkIcon:SetRawImage(perkConfig.Icon)
    --        self.ImgPerkIcon.color = CS.UnityEngine.Color(1,1,1,1)
    --    end
    --end
end

--设置技能选择状态
function XUIBrilliantWalkStageSkillSwitchGrid:SetSkillActive(active)
    self.BtnActive.gameObject:SetActiveEx(not active)
    self.BtnDisactive.gameObject:SetActiveEx(active)
end

--点击激活按钮
function XUIBrilliantWalkStageSkillSwitchGrid:OnBtnActive()
    self.RootUi:OnBtnActiveSkill(self)
end

--点击取消激活按钮
function XUIBrilliantWalkStageSkillSwitchGrid:OnBtnDisactive()
    self.RootUi:OnBtnDisactiveSkill(self)
end

return XUIBrilliantWalkStageSkillSwitchGrid