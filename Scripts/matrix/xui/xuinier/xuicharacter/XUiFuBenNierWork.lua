local XUiFuBenNierWork = XLuaUiManager.Register(XLuaUi, "UiFuBenNierWork")
local XUiGridNierPODSkill = require("XUi/XUiNieR/XUiCharacter/XUiGridNierPODSkill")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiFuBenNierWork:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnTongBlue.CallBack = function() self:OnBtnSkillUpLevelClick() end
    self.BtnClickItem.CallBack = function() self:OnTickJumpClick() end
    self:BindHelpBtn(self.BtnHelp, "NierWorkHelp")
    self:InitSceneRoot()
end

function XUiFuBenNierWork:OnStart()
    self.GirdSkillList = {}

end

function XUiFuBenNierWork:OnEnable()
    self.NierPOD = XDataCenter.NieRManager.GetNieRPODData()
    if not self.AssetPanel then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, self.NierPOD:GetUpSkillLevelItem())
        self.AssetPanel:RegisterJumpCallList({[1] = function()
            self:OnTickJumpClick()
        end })
    end
    self:UpdatePODInfo()
    self:UpDateNierSkill()
    self:UpdateRoleModel()
end

function XUiFuBenNierWork:OnDisable()

end

function XUiFuBenNierWork:OnDestroy()

end

function XUiFuBenNierWork:UpdatePODInfo()
    local podLevel = self.NierPOD:GetNieRPODLevel()
    local isPodMaxLevel = self.NierPOD:CheckNieRPODMaxLevel()
    local podExp = self.NierPOD:GetNieRPODExp()
    local podMaxExp = self.NierPOD:GetNieRPODMaxExp()
    -- self.TitleTxt.text = self.NierPOD:GetNieRPODName()
    self.TxtPODLevel.text = podLevel
    if not isPodMaxLevel then
        self.TxtExpNum.text = string.format("<color=#7fb715><size=26>%s</size></color>/%s", podExp, podMaxExp)
    else
        self.TxtExpNum.text = string.format("<color=#7fb715><size=26>MAX</size></color>")
    end

    self.ImgExpSlider.fillAmount = podExp / podMaxExp
end

function XUiFuBenNierWork:UpDateNierSkill()
    local nierPODSkills = self.NierPOD:GetNieRPODSkillList()
    self.NieRPODSkills = nierPODSkills
    for index, skillCfg in ipairs(nierPODSkills) do
        local grid
        if not self.GirdSkillList[index] then
            local ui
            local parent = self.PanelDropContent

            if index == 1 then
                ui = self.GridSubSkill
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(parent, false)
                grid = XUiGridNierPODSkill.New(ui, self)
            else
                ui = CS.UnityEngine.Object.Instantiate(self.GridSubSkill)
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(parent, false)
                grid = XUiGridNierPODSkill.New(ui, self)
            end
            self.GirdSkillList[index] = grid
            grid:SetSelectStatue(false)
        else
            grid = self.GirdSkillList[index]
        end
        grid:RefreShData(skillCfg, index)

    end
    if not self.CurSelectSkillIndex then
        for index, skillCfg in ipairs(nierPODSkills) do
            if self.NierPOD:CheckNieRPODSkillActive(skillCfg.SkillId) then
                self:OnSkillClick(index)
                break
            end
        end
    end
end

function XUiFuBenNierWork:UpdateSkillInfo()
    if not self.CurSelectSkillIndex then return end
    local index = self.CurSelectSkillIndex
    local skillId = self.NieRPODSkills[index].SkillId
    local skillLv = self.NierPOD:GetNieRPODSkillLevelById(skillId)
    local maxSkillLv = XNieRConfigs.GetNieRSupportMaxSkillLevelById(skillId)
    local skillName = self.NierPOD:GetNieRPODSkillName(skillId)
    local skillDesc = self.NierPOD:GetNieRPODSkillDesc(skillId)
    local skillStr = string.format("<color=#7fb715><size=32>%s</size></color>\n%s", skillName, skillDesc)
    self.TxtContentNoticeNow.text = skillStr


    if skillLv >= maxSkillLv then
        self.PanelBtn.gameObject:SetActiveEx(false)
        self.ImgJiantou.gameObject:SetActiveEx(false)
        self.PanelShowNext.gameObject:SetActiveEx(false)
        self.ImgMax.gameObject:SetActiveEx(true)
    else
        self.ImgJiantou.gameObject:SetActiveEx(true)
        self.PanelShowNext.gameObject:SetActiveEx(true)
        self.PanelBtn.gameObject:SetActiveEx(true)
        self.ImgMax.gameObject:SetActiveEx(false)
        local canUpLv, desc = self.NierPOD:CheckNieRPODSkillUpLevel(skillId)
        if canUpLv then
            self.TxtTipsCondit.text = ""
        else
            self.TxtTipsCondit.text = desc
        end
        local nextSkillInfo = XNieRConfigs.GetNieRSupportSkillClientConfig(skillId, skillLv + 1)
        local nextSkillStr = string.format("<color=#7fb715><size=32>%s</size></color>\n%s", nextSkillInfo.Name, nextSkillInfo.Desc)
        self.TxtContentNoticeNext.text = nextSkillStr
        local upLvItemId, upLvItemCounts = self.NierPOD:GetNieRPODSkillUpLevelItem(skillId)

        self.TextAT.text = CS.XTextManager.GetText("NieRPODSkillUpLevelNeed", "")--XDataCenter.ItemManager.GetItemName(upLvItemId)
        self.ImgATIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(upLvItemId))
        self.TxtATNums.text = upLvItemCounts

    end
end

function XUiFuBenNierWork:OnSkillClick(index)
    if self.CurSelectSkillIndex == index then return end
    local skillId = self.NieRPODSkills[index].SkillId
    local active, desc = self.NierPOD:CheckNieRPODSkillActive(skillId)
    if not active then
        XUiManager.TipMsg(desc)
    else
        local grid
        if self.CurSelectSkillIndex then
            grid = self.GirdSkillList[self.CurSelectSkillIndex]
            grid:SetSelectStatue(false)
        end
        self.CurSelectSkillIndex = index
        grid = self.GirdSkillList[self.CurSelectSkillIndex]
        grid:SetSelectStatue(true)
        self:UpdateSkillInfo()
    end
end

function XUiFuBenNierWork:OnBtnBackClick()
    self:Close()
end

function XUiFuBenNierWork:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFuBenNierWork:OnBtnSkillUpLevelClick()
    if not self.CurSelectSkillIndex then return end
    local skillId = self.NieRPODSkills[self.CurSelectSkillIndex].SkillId
    XDataCenter.NieRManager.NieRUpgradeSupportSkill(skillId, function()
        self:UpDateNierSkill()
        self:UpdateSkillInfo()
        XUiManager.TipMsg(CS.XTextManager.GetText("NieRPODSkillUpLevelSuccess"))
    end)
end

function XUiFuBenNierWork:OnTickJumpClick()
    local item = XDataCenter.ItemManager.GetItem(self.NierPOD:GetUpSkillLevelItem())
    local data = {
        Id = item.Id,
        Count = item ~= nil and tostring(item.Count) or "0"
    }
    XLuaUiManager.Open("UiTip", data)
end

function XUiFuBenNierWork:InitSceneRoot()
    local root = self.UiModelGo.transform
    -- if self.PanelRoleModel then
    --     self.PanelRoleModel:DestroyChildren()
    -- end
    self.PanelRoleModel = root:FindTransform("PanelModelCase1")
    -- self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    -- self.ImgEffectLogoGouzao = root:FindTransform("ImgEffectLogoGouzao")
    -- self.ImgEffectLogoGanran = root:FindTransform("ImgEffectLogoGanran")
    -- self.CameraFar = {
    --     root:FindTransform("UiCamFarLv"),
    --     root:FindTransform("UiCamFarGrade"),
    --     root:FindTransform("UiCamFarQuality"),
    --     root:FindTransform("UiCamFarSkill"),
    --     root:FindTransform("UiCamFarrExchange"),
    -- }
    -- self.CameraNear = {
    --     root:FindTransform("UiCamNearLv"),
    --     root:FindTransform("UiCamNearGrade"),
    --     root:FindTransform("UiCamNearQuality"),
    --     root:FindTransform("UiCamNearSkill"),
    --     root:FindTransform("UiCamNearrExchange"),
    -- }
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

--更新模型
function XUiFuBenNierWork:UpdateRoleModel()

    self.RoleModelPanel:UpdateBossModel(self.NierPOD:GetNieRPODModel(), self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiNieRPOD, function(model)
        -- self.PanelDrag.Target = model.transform
    end)
end