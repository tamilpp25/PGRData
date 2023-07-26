local XUiPanelCombination = XClass(nil, "XUiPanelCombination")
local XUiGridSuitDetail = require("XUi/XUiEquipAwarenessReplace/XUiGridSuitDetail")
local CSTextManagerGetText = CS.XTextManager.GetText
local Select= CS.UiButtonState.Select 
local Normal = CS.UiButtonState.Normal
local StateList = {"Normal", "Select"}

---@class XUiPanelCombination
function XUiPanelCombination:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XUiDrawOptional
    self.Parent = parent
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiPanelCombination:SetData(index, drawId, goodsType, isSelect)
    self.Index = index
    self.DrawId = drawId
    self.GoodsType = goodsType
    self.Combination = XDataCenter.DrawManager.GetDrawCombination(drawId)

    -- 活动中标记
    local drawInfo = XDataCenter.DrawManager.GetDrawInfo(self.DrawId)
    self.InActivityTag.gameObject:SetActiveEx(drawInfo.EndTime > 0)

    -- 已选中标记
    self.SelectTag.gameObject:SetActiveEx(self.Parent.LastSelectDrawId == drawId)

    -- 商品图片
    if self.GoodsType == XArrangeConfigs.Types.Character then
        self:SetCharacterData()
    elseif self.GoodsType == XArrangeConfigs.Types.Weapon then
        self:SetEquipData()
    elseif self.GoodsType == XArrangeConfigs.Types.Partner then
        self:SetPartnerData()
    end

    -- 背景图、概率
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    local probabilityInfo = drawAimProbability[self.DrawId]
    local showProbability = probabilityInfo and probabilityInfo.UpProbabilityDesc ~= nil
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        local panelProbability = uiObj:GetObject("PanelProbability")
        panelProbability.gameObject:SetActiveEx(showProbability)
        uiObj:GetObject("Bg"):SetRawImage(probabilityInfo.Bg)
        
        if showProbability then
            panelProbability:SetRawImage(probabilityInfo.ProbabilityBg)

            local havePercent = probabilityInfo.UpProbabilityPercent ~= nil
            local txtProbability = uiObj:GetObject("TxtProbability")
            local txtProbability2 = uiObj:GetObject("TxtProbability2")
            txtProbability.gameObject:SetActiveEx(havePercent)
            txtProbability2.gameObject:SetActiveEx(not havePercent)

            if havePercent then
                txtProbability.text = probabilityInfo.UpProbabilityDesc
                uiObj:GetObject("TxtProbabilityPercent").text = probabilityInfo.UpProbabilityPercent
            else
                txtProbability2.text = probabilityInfo.UpProbabilityDesc
            end
        end
    end

    -- 选中
    self:SetSelectState(isSelect)
end

function XUiPanelCombination:SetCharacterData()
    -- 随机泛用机体
    if self.Combination.GoodsId == nil or #self.Combination.GoodsId == 0 then
        self:SetCharacterDataEmpty()
        return
    end

    self.BtnHelp.gameObject:SetActiveEx(true)
    self.CharId = self.Combination.GoodsId[1]

    -- 已拥有
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(self.CharId)
    self.TxtOwn.gameObject:SetActiveEx(isOwn)

    -- 图片
    local halfBodyImage = XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharId)

    -- 名字
    local name = XCharacterConfigs.GetCharacterLogName(self.CharId)

    -- 职业
    local career = XCharacterConfigs.GetCharDetailCareer(self.CharId)
    local careerConfig = XCharacterConfigs.GetNpcTypeTemplate(career)
    local careerIcon = careerConfig.Icon

    -- 能量
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.CharId)
    local elementList = detailConfig.ObtainElementList
    local elementInfoList = {}
    for i, eleId in ipairs(elementList) do
        local eleValue = detailConfig.ObtainElementValueList[i]
        table.insert(elementInfoList, {Id = eleId, Value = eleValue})
    end
    table.sort(elementInfoList, function(a, b) 
        return a.Value > b.Value
    end)

    -- 刷新
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        uiObj:GetObject("RoleMask").gameObject:SetActiveEx(true)
        uiObj:GetObject("Bg2").gameObject:SetActiveEx(true)
        uiObj:GetObject("RImgRole"):SetRawImage(halfBodyImage)
        uiObj:GetObject("TxtName").text = name
        if uiObj:GetObject("Bg3") then
            uiObj:GetObject("Bg3").gameObject:SetActiveEx(true)
        end
        local rawImgCareerIcon = uiObj:GetObject("RawImgCareerIcon")
        rawImgCareerIcon.gameObject:SetActiveEx(true)
        rawImgCareerIcon:SetRawImage(careerIcon)

        -- 能量
        for i = 1, 2 do
            local rImg = uiObj:GetObject("RImgCharElement" .. i)
            if elementInfoList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XCharacterConfigs.GetCharElement(elementInfoList[i].Id)
                rImg:SetRawImage(elementConfig.Icon2)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiPanelCombination:SetCharacterDataEmpty()
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.TxtOwn.gameObject:SetActiveEx(false)

    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        uiObj:GetObject("RawImgCareerIcon").gameObject:SetActiveEx(false)
        uiObj:GetObject("RoleMask").gameObject:SetActiveEx(false)
        uiObj:GetObject("Bg2").gameObject:SetActiveEx(false)
        if uiObj:GetObject("Bg3") then
            uiObj:GetObject("Bg3").gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelCombination:SetEquipData()
    self.EquipTemplateId = self.Combination.GoodsId[1]

    -- 已拥有
    local isOwn = XDataCenter.EquipManager.IsOwnEquip(self.EquipTemplateId)
    self.TxtOwn.gameObject:SetActiveEx(isOwn)

    -- 武器图、推荐角色图
    local weaponIcon = XDataCenter.EquipManager.GetEquipLiHuiPath(self.EquipTemplateId)
    local equipCfg = XEquipConfig.GetEquipCfg(self.EquipTemplateId)
    local charId = equipCfg.RecommendCharacterId
    local haveChar = charId and charId ~= 0
    local charIcon = nil
    local roleName = nil
    if haveChar then
        charIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId, true)
        roleName = XCharacterConfigs.GetCharacterLogName(charId)
    end

    -- 刷新
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        local rImgWeapon = uiObj:GetObject("RImgWeapon")
        rImgWeapon:SetRawImage(weaponIcon)
        self:CheckIconPosAndSizeChange(rImgWeapon)

        local rImgRole = uiObj:GetObject("RImgRole")
        rImgRole.gameObject:SetActiveEx(haveChar)
        uiObj:GetObject("WeaponInfo").gameObject:SetActiveEx(haveChar)
        if haveChar then
            rImgRole:SetRawImage(charIcon)
            uiObj:GetObject("TxtRoleName").text = roleName
        end
    end
end

function XUiPanelCombination:SetPartnerData()
    self.PartnerTemplateId = self.Combination.GoodsId[1]

    -- 已拥有
    local isOwn = XDataCenter.PartnerManager.GetPartnerCountByTemplateId(self.PartnerTemplateId) > 0
    self.TxtOwn.gameObject:SetActiveEx(isOwn)

    -- 辅助机图、推荐角色图
    local partnerIcon = XPartnerConfigs.GetPartnerTemplateLiHuiPath(self.PartnerTemplateId)
    local partnerCfg = XPartnerConfigs.GetPartnerTemplateById(self.PartnerTemplateId)
    local charId = partnerCfg.RecommendCharacterId
    local haveChar = charId and charId ~= 0
    local charIcon = nil
    local roleName = nil
    if haveChar then
        charIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(charId, true)
        roleName = XCharacterConfigs.GetCharacterLogName(charId)
    end

    -- 刷新
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        local rImgWeapon = uiObj:GetObject("RImgWeapon")
        rImgWeapon:SetRawImage(partnerIcon)
        self:CheckIconPosAndSizeChange(rImgWeapon)

        local rImgRole = uiObj:GetObject("RImgRole")
        rImgRole.gameObject:SetActiveEx(haveChar)
        uiObj:GetObject("WeaponInfo").gameObject:SetActiveEx(haveChar)
        if haveChar then
            rImgRole:SetRawImage(charIcon)
            uiObj:GetObject("TxtRoleName").text = roleName
        end
    end
end

function XUiPanelCombination:SetSelectState(isSelect)
    local state = isSelect and Select or Normal
    self.BtnInfo:SetButtonState(state)
end

function XUiPanelCombination:AutoAddListener()
    self.BtnInfo.ExitCheck = false
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnClickBtnInfo)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelp)
end

function XUiPanelCombination:OnClickBtnInfo()
    self.Parent:SelectCombination(self.DrawId)
end

function XUiPanelCombination:OnBtnHelp()
    if self.GoodsType == XArrangeConfigs.Types.Character then
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", self.CharId)
    elseif self.GoodsType == XArrangeConfigs.Types.Weapon then
        XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(self.EquipTemplateId)
    elseif self.GoodsType == XArrangeConfigs.Types.Partner then
        local partnerData = { Id = 0, TemplateId = self.PartnerTemplateId }
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        XLuaUiManager.Open("UiPartnerPreview", partner)
    end
end

-- 检测图标的位置和大小是否需要变化
function XUiPanelCombination:CheckIconPosAndSizeChange(weaponIcon)
    local rectTrans = weaponIcon:GetComponent("RectTransform")
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    local pbCfg = drawAimProbability[self.DrawId]

    -- 检测位置
    local changPos = pbCfg.IsChangePos == 1
    if not self.DefaultWeaponLocalPosition then
        self.DefaultWeaponLocalPosition = rectTrans.localPosition
    end
    if changPos then
        rectTrans.localPosition = CS.UnityEngine.Vector3(pbCfg.IconPosX, pbCfg.IconPosY, 0)
    else
        rectTrans.localPosition = self.DefaultWeaponLocalPosition
    end

    -- 检测大小
    local changSize = pbCfg.IsChangeSize == 1
    if not self.DefaultWeaponSizeDelta then
        self.DefaultWeaponSizeDelta = rectTrans.sizeDelta
    end
    if changSize then
        rectTrans.sizeDelta = CS.UnityEngine.Vector2(pbCfg.IconWidth, pbCfg.IconHeight)
    else
        rectTrans.sizeDelta = self.DefaultWeaponSizeDelta
    end

    -- 检测旋转
    local changRot = pbCfg.IsChangeRot == 1
    if not self.DefaultWeaponRotation then
        self.DefaultWeaponRotation = rectTrans.localRotation
    end
    if changRot then
        rectTrans.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, pbCfg.RotZ)
    else
        rectTrans.localRotation = self.DefaultWeaponRotation
    end
end

return XUiPanelCombination