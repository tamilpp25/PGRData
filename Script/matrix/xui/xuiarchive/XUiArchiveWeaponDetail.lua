
--
-- Author: wujie
-- Note: 图鉴武器详情界面

local XUiArchiveWeaponDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveWeaponDetail")

local XUiGridArchiveEquipSetting = require("XUi/XUiArchive/XUiGridArchiveEquipSetting")

local delayTime = CS.XGame.ClientConfig:GetInt("ArchiveWeaponShowDelayTime")

local FirstIndex = 1

function XUiArchiveWeaponDetail:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:InitBtnGroup()

    self.LeftRightIndex = 0
    self.LeftRightMax = 1
    self.LeftRightMin = 1

    self.IsSettingOpen = false

    self.GridSettingList = {
        XUiGridArchiveEquipSetting.New(self.GridSetting1),
        XUiGridArchiveEquipSetting.New(self.GridSetting2),
        XUiGridArchiveEquipSetting.New(self.GridSetting3),
        XUiGridArchiveEquipSetting.New(self.GridSetting4),
        XUiGridArchiveEquipSetting.New(self.GridSetting5),
    }

    self.GridStoryList = {
        XUiGridArchiveEquipSetting.New(self.GridStory1),
        XUiGridArchiveEquipSetting.New(self.GridStory2),
        XUiGridArchiveEquipSetting.New(self.GridStory3),
        XUiGridArchiveEquipSetting.New(self.GridStory4),
        XUiGridArchiveEquipSetting.New(self.GridStory5),
    }

    self:AutoAddListener()
end

function XUiArchiveWeaponDetail:OnStart(templateIdList,index)
    self:InitScene3DRoot()
    self:Init(templateIdList,index)
end

function XUiArchiveWeaponDetail:Init(templateIdList,index)
    local templateId = templateIdList[index]
    if not templateId then
        return
    end
    self.TemplateId = templateId
    self.TemplateIdList = templateIdList
    self.TemplateIndex = index

    if XDataCenter.ArchiveManager.IsNewWeapon(templateId) then
        XDataCenter.ArchiveManager.RequestUnlockWeapon({templateId})
    end

    self:UpdateResume()
    self:UpdateSetting()
    self:UpdateSkill()
    self:UpdateSwitch()
    self:CheckNextMonsterAndPreMonster()
end

function XUiArchiveWeaponDetail:OnDestroy()
    self.Scene3DRoot.PanelWeaponPlane.gameObject:SetActiveEx(true)
end

function XUiArchiveWeaponDetail:InitBtnGroup()
    self.BtnSwitchModelList = {
        self.BtnSwitchModel1,
        self.BtnSwitchModel2,
        self.BtnSwitchModel3,
        self.BtnSwitchModel4,
    }
    self.BtnGroupSwitchModel:Init(self.BtnSwitchModelList, handler(self,self.OnTabBtnGroupClick))
end

function XUiArchiveWeaponDetail:InitScene3DRoot()
    if self.Scene3DRoot then return end
    self.Scene3DRoot = {}
    local root = self.Scene3DRoot
    local sceneRoot = self.UiSceneInfo.Transform
    root.Transform = sceneRoot
    root.AutoRationPanel = self.UiModelGo:FindTransform("PanelWeapon"):GetComponent(typeof(CS.XAutoRotation))
    root.PanelEffect = self.UiModelGo:FindTransform("EffectGo")
    root.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    root.PanelWeaponPlane.gameObject:SetActiveEx(false)
end

function XUiArchiveWeaponDetail:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnNext.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLast.CallBack = function()
        self:OnBtnLastClick()
    end
end

function XUiArchiveWeaponDetail:UpdateWeaponModel(modelConfig)
    local root = self.Scene3DRoot
    XScheduleManager.ScheduleOnce(function()
            XModelManager.LoadWeaponModel(modelConfig.ModelId, root.AutoRationPanel.transform, modelConfig.TransformConfig, self.Name, function(model)
                    model.gameObject:SetActiveEx(true)
                    local panelEffect = root.PanelEffect
                    panelEffect.gameObject:SetActiveEx(false)
                    panelEffect.gameObject:SetActiveEx(true)
                end, {gameObject = self.GameObject, IsDragRotation = true}, self.PanelDrag)
        end, delayTime)
end

function XUiArchiveWeaponDetail:UpdateResume()
    local templateId = self.TemplateId
    local weaponName = XDataCenter.EquipManager.GetEquipName(templateId)
    self.TxtWeaponNameHorizontal.text = weaponName
    self.TxtWeaponNameVertical.text = weaponName
    self.TxtWeaponMaxLv.text = XDataCenter.EquipManager.GetEquipMaxLevel(templateId)
    self.TxtWeaponMaxBreakthrough.text = XDataCenter.EquipManager.GetEquipMaxBreakthrough(templateId)
end

function XUiArchiveWeaponDetail:UpdateSetting()
    local templateId = self.TemplateId
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, {XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON_SETTING_RED}, templateId)
    local newSettingIdList = XDataCenter.ArchiveManager.GetNewWeaponSettingIdList(templateId)
    if newSettingIdList and #newSettingIdList > 0 then
        XDataCenter.ArchiveManager.RequestUnlockWeaponSetting(newSettingIdList)
    end

    local settingDataList = XArchiveConfigs.GetWeaponSettingList(templateId)
    local settingType
    local showedSettingCount = 0
    local showedStoryCount = 0
    local grid
    for _, settingData in ipairs(settingDataList) do
        settingType = settingData.Type
        if settingType == XArchiveConfigs.SettingType.Setting then
            showedSettingCount = showedSettingCount + 1
            grid = self.GridSettingList[showedSettingCount]
            if grid then
                grid:Refresh(XArchiveConfigs.SubSystemType.Weapon, settingData)
                grid.GameObject:SetActiveEx(true)
            else
                local path = XArchiveConfigs.GetWeaponSettingPath()
                local tempStr = "XUiArchiveWeaponDetail:UpdateSetting函数错误，武器数据个数大于显示结点个数, weaponid Id是 "
                XLog.Error(tempStr .. templateId .. ", settingid is " .. settingData.Id .. "weapon setting表路径是" .. path)
            end
        elseif settingType == XArchiveConfigs.SettingType.Story then
            showedStoryCount = showedStoryCount + 1
            grid = self.GridStoryList[showedStoryCount]
            if grid then
                grid:Refresh(XArchiveConfigs.SubSystemType.Weapon, settingData)
                grid.GameObject:SetActiveEx(true)
            else
                local path = XArchiveConfigs.GetWeaponSettingPath()
                local tempStr = "XUiArchiveWeaponDetail:UpdateSetting函数错误，武器数据个数大于显示结点个数, weaponid Id是 "
                XLog.Error(tempStr .. templateId .. ", settingid is " .. settingData.Id .. "weapon setting表路径是" .. path)
            end
        end
    end

    if showedSettingCount == 0 then
        self.PanelSetting.gameObject:SetActiveEx(false)
    else
        self.PanelSetting.gameObject:SetActiveEx(true)
        for i = showedSettingCount+1, #self.GridSettingList do
            self.GridSettingList[i].GameObject:SetActiveEx(false)
        end
    end

    if showedStoryCount == 0 then
        self.PanelStory.gameObject:SetActiveEx(false)
    else
        self.PanelStory.gameObject:SetActiveEx(true)
        for i = showedStoryCount+1, #self.GridStoryList do
            self.GridStoryList[i].GameObject:SetActiveEx(false)
        end
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelSettingContent)
end

function XUiArchiveWeaponDetail:UpdateSkill()
    local weaponSkillInfo = XDataCenter.EquipManager.GetOriginWeaponSkillInfo(self.TemplateId)
    if weaponSkillInfo.Name and weaponSkillInfo.Description then
        self.PanelNoSkill.gameObject:SetActiveEx(false)
        self.PanelSkill.gameObject:SetActiveEx(true)
        self.TxtSkillName.text = weaponSkillInfo.Name
        self.TxtSkillDesc.text = weaponSkillInfo.Description
    else
        self.PanelNoSkill.gameObject:SetActiveEx(true)
        self.PanelSkill.gameObject:SetActiveEx(false)
    end
end

function XUiArchiveWeaponDetail:UpdateSwitch()
    self.ModelCfgList = XEquipConfig.GetWeaponModelCfgList(self.TemplateId, self.Name, 0)
    local modelCount = #self.ModelCfgList

    self.Scene3DRoot.PanelWeaponPlane.gameObject:SetActiveEx(modelCount == 0)

    local firstModelIndex = 1
    if modelCount <= firstModelIndex then
        self.PanelWeaponSwitch.gameObject:SetActiveEx(false)
        if modelCount == firstModelIndex then
            self:UpdateWeaponModel(self.ModelCfgList[firstModelIndex])
        end
    else
        self.PanelWeaponSwitch.gameObject:SetActiveEx(true)
        self.SelectWeaponIndex = nil
        for i, btn in ipairs(self.BtnSwitchModelList) do
            btn.gameObject:SetActiveEx(i <= modelCount)
        end
        if not self.SelectWeaponIndex and modelCount > 0 then
            self.BtnGroupSwitchModel:SelectIndex(1)
        end
    end
end

function XUiArchiveWeaponDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    self:Init(self.TemplateIdList,self.NextIndex)
end

function XUiArchiveWeaponDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    self:Init(self.TemplateIdList,self.PreviousIndex)
end

function XUiArchiveWeaponDetail:CheckNextMonsterAndPreMonster()
    self.NextIndex = self:CheckIndex(self.TemplateIndex + 1)
    self.PreviousIndex = self:CheckIndex(self.TemplateIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckIndex(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckIndex(#self.TemplateIdList)
    end
end

function XUiArchiveWeaponDetail:CheckIndex(index)
    return self.TemplateIdList[index] and index or 0
end

-----------------------------------事件相关----------------------------------------->>>
-- 切换武器形态
function XUiArchiveWeaponDetail:OnTabBtnGroupClick(index)
    if self.SelectWeaponIndex == index or not self.ModelCfgList or #self.ModelCfgList <= 1 then return end
    self.SelectWeaponIndex = index
    self:UpdateWeaponModel(self.ModelCfgList[index])
end

function XUiArchiveWeaponDetail:OnCheckRedPoint(count)
    if count < 0 then
        self.PanelSettingRedPoint.gameObject:SetActiveEx(false)
        self.PanelStoryRedPoint.gameObject:SetActiveEx(false)
    else
        local newSettingIdList = XDataCenter.ArchiveManager.GetNewWeaponSettingIdList(self.TemplateId)
        if newSettingIdList then
            local type
            local isShowSettingReddot = false
            local isShowStoryReddot = false
            for _, id in ipairs(newSettingIdList) do
                type = XArchiveConfigs.GetWeaponSettingType(id)
                if type == XArchiveConfigs.SettingType.Setting then
                    isShowSettingReddot = true
                elseif type == XArchiveConfigs.SettingType.Story then
                    isShowStoryReddot = true
                end
            end
            self.PanelSettingRedPoint.gameObject:SetActiveEx(isShowSettingReddot)
            self.PanelStoryRedPoint.gameObject:SetActiveEx(isShowStoryReddot)
        else
            self.PanelSettingRedPoint.gameObject:SetActiveEx(false)
            self.PanelStoryRedPoint.gameObject:SetActiveEx(false)
        end
    end
end
-----------------------------------事件相关-----------------------------------------<<<