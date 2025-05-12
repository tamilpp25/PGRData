local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

local XUiEquipPreviewV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipPreviewV2P6")

function XUiEquipPreviewV2P6:OnAwake()
    -- UI初始化
    self.PanelRole.gameObject:SetActiveEx(false)

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")

    self.RoleUiObjList = { self.GridRole }
    self:SetButtonCallBack()
    self:InitPanelAsset()
end

function XUiEquipPreviewV2P6:OnStart(templateId)
    self.TemplateId = templateId
    self.IsWeapon = XMVCA.XEquip:IsEquipWeapon(self.TemplateId)
    self.IsAwareness = XMVCA.XEquip:IsEquipAwareness(self.TemplateId)
end

function XUiEquipPreviewV2P6:OnEnable()
    self:UpdateView()
end

function XUiEquipPreviewV2P6:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

function XUiEquipPreviewV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end

function XUiEquipPreviewV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipPreviewV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end


-- 初始化武器模型/意识立绘
function XUiEquipPreviewV2P6:InitModel()
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if self.IsWeapon then
        self.PanelWeapon.gameObject:SetActiveEx(true)
        local breakthroughTimes = 0
        local resonanceCount = 0
        local modelTransformName = "UiEquipDetail"
        local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(self.TemplateId, modelTransformName, breakthroughTimes, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(
                modelConfig.ModelId,
                self.PanelWeapon,
                modelConfig.TransformConfig,
                modelTransformName,
                nil,
                {gameObject = self.GameObject, usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW, IsDragRotation = true, AntiClockwise = true},
                self.PanelDrag
            )
        end
    elseif self.IsAwareness then
        self:ReleaseModel()
        local breakthroughTimes = 0

        local resPath = XMVCA.XEquip:GetEquipLiHuiPath(self.TemplateId, breakthroughTimes)
        self.Loader = self.Loader or self.Transform:GetLoader()
        local texture = self.Loader:Load(resPath)
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)

        self:ReleaseLihuiTimer()
        self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            self.LihuiTimer = nil
        end,500)
    end
end

-- 释放模型
function XUiEquipPreviewV2P6:ReleaseModel()
    
end

-- 释放定时器
function XUiEquipPreviewV2P6:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipPreviewV2P6:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

function XUiEquipPreviewV2P6:UpdateView()
    self:InitModel()
    self:UpdateEquipInfo()
    self:UpdateEquipAttr()

    if self.IsWeapon then
        self:UpdateEquipSkillDesc()
        self:UpdateRoleList()
    end

    if self.IsAwareness then
        self:UpdateSuitSkillDesc()
    end
end

-- 刷新武器信息
function XUiEquipPreviewV2P6:UpdateEquipInfo()
    local star = XMVCA.XEquip:GetEquipStar(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
    end
    self.TxtEquipName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)

    self.TxtWeaponType.gameObject:SetActiveEx(self.IsWeapon)
    if self.IsWeapon then 
        local equipType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipType(self.TemplateId)
        local weaponGroupCfg = XMVCA.XArchive:GetWeaponGroupByType(equipType)
        self.TxtWeaponType.text = weaponGroupCfg and weaponGroupCfg.GroupName or ""
    end

    if XTool.DebugIsShowItemIdOnUi() then
        self.TxtEquipName.text = self.TxtEquipName.text .. string.format("(Id:%s)", self.TemplateId)
    end
end

-- 刷新装备属性
function XUiEquipPreviewV2P6:UpdateEquipAttr()
    local attrMap = XMVCA.XEquip:GetTemplateEquipAttrMap(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        self["PanelAttr" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtName" .. i].text = attrInfo.Name
            self["TxtAttr" .. i].text = attrInfo.Value
        end
    end
end

-- 刷新技能详情
function XUiEquipPreviewV2P6:UpdateEquipSkillDesc()
    local weaponSkillInfo = XMVCA.XEquip:GetEquipWeaponSkillInfo(self.TemplateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(false)
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新适用角色列表
function XUiEquipPreviewV2P6:UpdateRoleList()
    self.PanelRole.gameObject:SetActiveEx(true)
    for _, uiObj in ipairs(self.RoleUiObjList) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local roleList = self._Control:GetEquipMatchRole(self.TemplateId)
    for i, role in pairs(roleList) do
        local uiObj = self.RoleUiObjList[i]
        if not uiObj then
            local go = CSInstantiate(self.GridRole, self.RoleContent)
            uiObj = go:GetComponent("UiObject")
            table.insert(self.RoleUiObjList, uiObj)
        end

        uiObj.gameObject:SetActiveEx(true)
        uiObj:GetObject("TxtRoleName").text = role.Name
        uiObj:GetObject("ImgTag").gameObject:SetActiveEx(role.IsRecommend)
    end
end

-- 刷新意识套装技能详情
function XUiEquipPreviewV2P6:UpdateSuitSkillDesc()
    local suitId = XMVCA.XEquip:GetEquipSuitId(self.TemplateId)
    local skillDesList = XMVCA.XEquip:GetEquipSuitSkillDescription(suitId)

    local noSuitSkill = true
    for i = 1, XEnumConst.EQUIP.SUIT_MAX_SKILL_COUNT do
        if skillDesList[i * 2] then
            self["TxtSkillDes" .. i].text = skillDesList[i * 2]
            self["TxtPos" .. i].text = XUiHelper.GetText("EquipSuitSkillPrefix" .. i * 2)
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(true)
            noSuitSkill = false
        else
            self["TxtSkillDes" .. i].gameObject:SetActiveEx(false)
        end
    end

    self.PanelWeaponSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(false)
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(not noSuitSkill)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(noSuitSkill)
end

return XUiEquipPreviewV2P6