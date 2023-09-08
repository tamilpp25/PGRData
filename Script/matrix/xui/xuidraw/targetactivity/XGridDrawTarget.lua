local XGridDrawTarget = XClass(nil, "XGridDrawTarget")
local Select= CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local StateList = {"Normal", "Select"}

---@class XGridDrawTarget
function XGridDrawTarget:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XUiDrawOptional
    self.Parent = parent
    XTool.InitUiObject(self)
    self:AutoAddListener()
    --self.PanelTabList.gameObject:SetActiveEx(false)
end

function XGridDrawTarget:SetData(index, templateId, goodsType, isSelect)
    self.Index = index
    self.TemplateId = templateId
    self.GoodsType = goodsType
    
    -- 活动中标记
    self.InActivityTag.gameObject:SetActiveEx(false)
    -- 已选中标记
    self.SelectTag.gameObject:SetActiveEx(self.Parent.LastSelectDrawId == templateId)

    -- 商品图片
    if self.GoodsType == XArrangeConfigs.Types.Character then
        self:SetCharacterData()
    end
    
    -- 选中
    self:SetSelectState(isSelect)
end

function XGridDrawTarget:GetTemplateId()
    return self.TemplateId
end

function XGridDrawTarget:SetCharacterData()
    -- 随机泛用机体
    if not XTool.IsNumberValid(self.TemplateId) then
        self:SetCharacterDataEmpty()
        return
    end

    self.BtnHelp.gameObject:SetActiveEx(true)
    self.CharId = self.TemplateId

    -- 已拥有
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(self.CharId)
    self.TxtOwn.gameObject:SetActiveEx(isOwn)

    -- 图片
    local halfBodyImage = XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharId)

    -- 名字
    local name = XMVCA.XCharacter:GetCharacterLogName(self.CharId)

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
    
    -- 背景
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local quality = characterAgency:GetCharacterInitialQuality(self.CharId)
    local bgUrl = XDrawConfigs.GetDrawActivityTargetRoleBgUrl(quality)
    local probabilityBgUrl = XDrawConfigs.GetDrawActivityTargetRoleProbabilityBgUrl(quality)

    -- 刷新
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        uiObj:GetObject("RoleMask").gameObject:SetActiveEx(true)
        uiObj:GetObject("Bg2").gameObject:SetActiveEx(true)
        uiObj:GetObject("PanelProbability").gameObject:SetActiveEx(true)
        uiObj:GetObject("RImgRole"):SetRawImage(halfBodyImage)
        uiObj:GetObject("TxtName").text = name
        local rawImgCareerIcon = uiObj:GetObject("RawImgCareerIcon")
        rawImgCareerIcon.gameObject:SetActiveEx(true)
        rawImgCareerIcon:SetRawImage(careerIcon)

        if uiObj:GetObject("Bg3") then
            uiObj:GetObject("Bg3").gameObject:SetActiveEx(true)
        end
        if not string.IsNilOrEmpty(bgUrl) then
            uiObj:GetObject("Bg"):SetRawImage(bgUrl)
        end
        if not string.IsNilOrEmpty(probabilityBgUrl) then
            uiObj:GetObject("PanelProbability"):SetRawImage(probabilityBgUrl)
        end

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

function XGridDrawTarget:SetCharacterDataEmpty()
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.TxtOwn.gameObject:SetActiveEx(false)

    local bgUrl = XDrawConfigs.GetDrawActivityTargetRoleBgUrl(XDrawConfigs.DrawTargetActivityNone)
    local probabilityBgUrl = XDrawConfigs.GetDrawActivityTargetRoleProbabilityBgUrl(XDrawConfigs.DrawTargetActivityNone)
    for _, stateName in ipairs(StateList) do
        local uiObj = self[stateName]
        uiObj:GetObject("RawImgCareerIcon").gameObject:SetActiveEx(false)
        uiObj:GetObject("RoleMask").gameObject:SetActiveEx(false)
        uiObj:GetObject("Bg2").gameObject:SetActiveEx(false)
        uiObj:GetObject("PanelProbability").gameObject:SetActiveEx(false)
        if uiObj:GetObject("Bg3") then
            uiObj:GetObject("Bg3").gameObject:SetActiveEx(false)
        end
        if not string.IsNilOrEmpty(bgUrl) then
            uiObj:GetObject("Bg"):SetRawImage(bgUrl)
        end
        if not string.IsNilOrEmpty(probabilityBgUrl) then
            uiObj:GetObject("PanelProbability"):SetRawImage(probabilityBgUrl)
        end
    end
end

function XGridDrawTarget:SetSelectState(isSelect)
    local state = isSelect and Select or Normal
    self.BtnInfo:SetButtonState(state)
end

function XGridDrawTarget:AutoAddListener()
    self.BtnInfo.ExitCheck = false
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnClickBtnInfo)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelp)
end

function XGridDrawTarget:OnClickBtnInfo()
    self.Parent:SelectTargetTemplate(self.TemplateId)
end

function XGridDrawTarget:OnBtnHelp()
    if self.GoodsType == XArrangeConfigs.Types.Character then
        XDataCenter.AutoWindowManager.StopAutoWindow()
        XLuaUiManager.Open("UiCharacterDetail", self.CharId)
    end
end

-- 检测图标的位置和大小是否需要变化
function XGridDrawTarget:CheckIconPosAndSizeChange(weaponIcon)
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

return XGridDrawTarget