local MAX_SKILL_DES_LINE_TWO = 2  -- 二件套技能说明最大行数
local MAX_SKILL_DES_LINE_FOUR = 4  -- 四件套技能说明最大行数

local XUiGridSuitDetail = XClass(nil, "XUiGridSuitDetail")

function XUiGridSuitDetail:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
    XTool.InitUiObject(self)
end

function XUiGridSuitDetail:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridSuitDetail:Refresh(suitId, defaultSuitIds, isBigIcon, desPrefix, site)
    self.SuitId = suitId

    if self.RImgIcon then
        if XMVCA.XEquip:IsDefaultSuitId(suitId) then
            self.RImgIcon.gameObject:SetActive(false)
        else
            local icon
            if isBigIcon then
                icon = XMVCA.XEquip:GetEquipSuitBigIconPath(suitId)
            else
                icon = XMVCA.XEquip:GetEquipSuitIconPath(suitId)
            end

            self.RImgIcon:SetRawImage(icon)
            self.RImgIcon.gameObject:SetActive(true)
        end
    end
    --意识套装没有质量等级，默认用套装第一个部位的品级
    if self.ImgQuality then
        if XMVCA.XEquip:IsDefaultSuitId(suitId) then
            self.ImgQuality.gameObject:SetActive(false)
        else
            local ids = XMVCA.XEquip:GetSuitEquipIds(self.SuitId)
            self.RootUi:SetUiSprite(self.ImgQuality, XMVCA.XEquip:GetEquipBgPath(ids[1]))
            self.ImgQuality.gameObject:SetActive(true)
        end
    end

    if self.ImgDefaultIcon then
        self.ImgDefaultIcon.gameObject:SetActive(XMVCA.XEquip:IsDefaultSuitId(suitId))
    end

    if self.ImgDefaultIconIsomer then
        self.ImgDefaultIconIsomer.gameObject:SetActive(suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.ISOMER)
    end

    if self.ImgDefaultIconNormal then
        self.ImgDefaultIconNormal.gameObject:SetActive(suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL)
    end

    if self.TxtName then
        if XMVCA.XEquip:IsDefaultSuitId(suitId) then
            self.PanelName.gameObject:SetActive(false)
        else
            self.TxtName.text = XMVCA.XEquip:GetSuitName(suitId)
            self.PanelName.gameObject:SetActive(true)
        end
    end

    if self.TxtDes then
        local des = XMVCA.XEquip:GetSuitDescription(suitId)
        self.TxtDes.text = desPrefix and string.format("(%s)", des) or des
    end

    if self.TxtNum then
        local suitNum

        if suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL then
            suitNum = XMVCA.XEquip:GetAwarenessCount(XEnumConst.CHARACTER.CharacterType.Normal)
        elseif suitId == XEnumConst.EQUIP.DEFAULT_SUIT_ID.NORMAL then
            suitNum = XMVCA.XEquip:GetAwarenessCount(XEnumConst.CHARACTER.CharacterType.Isomer)
        else
            suitNum = XMVCA.XEquip:GetEquipCountInSuit(suitId, site)
        end

        self.TxtNum.text = suitNum
    end

    if self.ImgUp then
        self.ImgUp.gameObject:SetActive(false)
    end

    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        if self["ImgGirdStar" .. i] then
            if i <= XMVCA.XEquip:GetSuitStar(suitId) then
                self["ImgGirdStar" .. i].gameObject:SetActive(true)
            else
                self["ImgGirdStar" .. i].gameObject:SetActive(false)
            end
        end
    end

    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId)
    for i = 1, XEnumConst.EQUIP.OLD_MAX_SUIT_SKILL_COUNT do
        local textObj = self["TxtSkillDesDetail" .. i]
        if textObj then
            if skillDesList[i] then
                local skillDes = skillDesList[i].SkillDes
                textObj.text = skillDes
                if desPrefix then
                    XScheduleManager.ScheduleOnce(function()
                        local rect = textObj.gameObject:GetComponent("RectTransform")
                        local desWidth = XUiHelper.CalcTextWidth(textObj)
                        local txtWidth = rect.sizeDelta.x

                        local maxLine = i == 1 and MAX_SKILL_DES_LINE_TWO or MAX_SKILL_DES_LINE_FOUR
                        local maxDesWidth = maxLine * txtWidth

                        local singleChar = string.Utf8Sub(skillDes, 1, 1)
                        textObj.text = singleChar
                        local singleCharWidth = XUiHelper.CalcTextWidth(textObj)

                        local spaceFix = 5
                        local maxCharNum = singleCharWidth ~= 0 and (math.ceil(maxDesWidth / singleCharWidth) - spaceFix) or spaceFix
                        textObj.text = desWidth > maxDesWidth and string.Utf8Sub(skillDes, 1, maxCharNum) .. [[......]] or skillDes
                    end, 0)
                end
                textObj.gameObject:SetActive(true)
            else
                textObj.gameObject:SetActive(false)
            end
        end
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, XMVCA.XEquip:GetSuitQualityIcon(suitId))
    end
end

function XUiGridSuitDetail:SetShowUp(isShow)
    if self.ImgUp then
        self.ImgUp.gameObject:SetActive(isShow)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridSuitDetail:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridSuitDetail:AutoInitUi()
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
    self.ImgDefaultIcon = XUiHelper.TryGetComponent(self.Transform, "ImgDefaultIcon", "Image")
    self.TxtNum = XUiHelper.TryGetComponent(self.Transform, "ImageNumBg/TxtNum", "Text")
    self.PanelName = XUiHelper.TryGetComponent(self.Transform, "PanelName", nil)
    self.TxtName = XUiHelper.TryGetComponent(self.Transform, "PanelName/TxtName", "Text")
    self.PanelSkillDes = XUiHelper.TryGetComponent(self.Transform, "PanelSkillDes", nil)
    self.TxtSkillDesDetail1 = XUiHelper.TryGetComponent(self.Transform, "PanelSkillDes/Image1/TxtSkillDesDetail1", "Text")
    self.TxtSkillDesDetail2 = XUiHelper.TryGetComponent(self.Transform, "PanelSkillDes/Image2/TxtSkillDesDetail2", "Text")
    self.TxtSkillDesDetail3 = XUiHelper.TryGetComponent(self.Transform, "PanelSkillDes/Image3/TxtSkillDesDetail3", "Text")
    self.ImgGirdStar1 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar1/ImgGirdStar1", "Image")
    self.ImgGirdStar2 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar2/ImgGirdStar2", "Image")
    self.ImgGirdStar3 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar3/ImgGirdStar3", "Image")
    self.ImgGirdStar4 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar4/ImgGirdStar4", "Image")
    self.ImgGirdStar5 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar5/ImgGirdStar5", "Image")
    self.ImgGirdStar6 = XUiHelper.TryGetComponent(self.Transform, "Stars/PaneStar6/ImgGirdStar6", "Image")
    self.BtnClick = XUiHelper.TryGetComponent(self.Transform, "BtnClick", "Button")
    self.ImgUp = XUiHelper.TryGetComponent(self.Transform, "ImgUp", "Image")
    self.ImgQuality = XUiHelper.TryGetComponent(self.Transform, "ImgQuality", "Image")
    self.TxtDes = XUiHelper.TryGetComponent(self.Transform, "TxtDes", "Text")
end

function XUiGridSuitDetail:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridSuitDetail:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridSuitDetail:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridSuitDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end
-- auto
function XUiGridSuitDetail:OnBtnClickClick()
    if self.ClickCb then self.ClickCb(self.SuitId, self) end
end

return XUiGridSuitDetail