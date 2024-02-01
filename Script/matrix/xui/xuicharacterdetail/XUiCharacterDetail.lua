---@class XUiCharacterDetail XUiCharacterDetail
---@field _Control XCharacterControl
local XUiCharacterDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterDetail")

local CharDetailUiType = {
    Detail = 1, --详细信息
    Parner = 2, --推荐角色
    Equip = 3, --推荐装备
}

local CHILD_UI_EQUIP = "UiPanelEquipInfo"
local CHILD_UI_TEAM = "UiPanelTeamInfo"

-- auto
-- Automatic generation of code, forbid to edit
function XUiCharacterDetail:InitAutoScript()
    self:AutoAddListener()
end

function XUiCharacterDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnArchive, self.OnBtnArchiveClick)
    self:RegisterClickEvent(self.BtnDetial, self.OnBtnDetialClick)
    self:RegisterClickEvent(self.BtnTeamRecomend, self.OnBtnTeamRecomendClick)
    self:RegisterClickEvent(self.BtnEquipRecomend, self.OnBtnEquipRecomendClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnPaneElementlClick, self.OnBtnElementDetailClick)
    self:RegisterClickEvent(self.BtnElement1, self.OnBtnElementDetailClick)
    self:RegisterClickEvent(self.BtnElement2, self.OnBtnElementDetailClick)
    self:RegisterClickEvent(self.BtnElement3, self.OnBtnElementDetailClick)
    self:RegisterClickEvent(self.BtnCareer, self.OnBtnCareerClick)
    self:RegisterClickEvent(self.BtnPanelGsClick, function ()
        self:OnBtnGeneralSkillClick()
    end)
    self:RegisterClickEvent(self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    self:RegisterClickEvent(self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
end
-- auto
function XUiCharacterDetail:OnBtnTeamRecomendClick()
    self:SwitchView(CharDetailUiType.Parner)
    self.Bg.gameObject:SetActiveEx(false)
    self.Bg2.gameObject:SetActiveEx(false)
end

function XUiCharacterDetail:OnBtnEquipRecomendClick()
    --self:SwitchView(CharDetailUiType.Equip)
    local isOwn = XMVCA:GetAgency(ModuleId.XCharacter):IsOwnCharacter(self.CharacterId)
    local isUnlock = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend)
    local canSet = isOwn and isUnlock
    XDataCenter.EquipGuideManager.OpenEquipGuideRecommend(self.CharacterId, not canSet)
end

function XUiCharacterDetail:OnBtnDetialClick()
    XUiHelper.StopAnimation()
    self:PlayAnimation("QieHuanDisable")
    -- self.BtnArchive.gameObject:SetActiveEx(true)
    self.BtnDetial.gameObject:SetActiveEx(false)
end

function XUiCharacterDetail:OnBtnArchiveClick()
    XUiHelper.StopAnimation()
    self:PlayAnimation("QieHuan")
    -- self.BtnArchive.gameObject:SetActiveEx(false)
    self.BtnDetial.gameObject:SetActiveEx(true)
end

function XUiCharacterDetail:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiCharacterDetail:OnBtnCareerClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Career)
end

function XUiCharacterDetail:OnBtnGeneralSkillClick(index)
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, index)
end

function XUiCharacterDetail:OnAwake()
    self:InitAutoScript()

    self.TxtElementDes = {
        [1] = self.TxtElementDes1,
        [2] = self.TxtElementDes2,
        [3] = self.TxtElementDes3
    }

    self.TxtElementValue = {
        [1] = self.TxtElementValue1,
        [2] = self.TxtElementValue2,
        [3] = self.TxtElementValue3
    }

    self.TxtSpecialDes = {
        [1] = self.TxtSpecialDes1,
        [2] = self.TxtSpecialDes2,
        [3] = self.TxtSpecialDes3
    }

    self.Txt = {
        [1] = self.Txt1,
        [2] = self.Txt2,
        [3] = self.Txt3
    }

    self.TxtGraphName = {
        [1] = self.TxtGraphName1,
        [2] = self.TxtGraphName2,
        [3] = self.TxtGraphName3,
        [4] = self.TxtGraphName4,
        [5] = self.TxtGraphName5,
        [6] = self.TxtGraphName6
    }
end

function XUiCharacterDetail:OnStart(CharacterId)
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(CharacterId)
    if not detailConfig then
        return
    end

    self.CharacterId = CharacterId

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PanelContentRtf = self.PanelContent:GetComponent("RectTransform")
    -- self.BtnArchive.gameObject:SetActiveEx(true)
    self.BtnDetial.gameObject:SetActiveEx(false)
    self.AssetPanel:Close()
    self.BtnEquipRecomend.gameObject:SetActiveEx(XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend))

    self:SwitchView(CharDetailUiType.Detail)
end

function XUiCharacterDetail:SwitchView(uiType)
    self.CurUiType = uiType
    self:UpdateStateView()
end


function XUiCharacterDetail:UpdateStateView()
    if self.CurUiType == CharDetailUiType.Detail then
        self.AssetPanel:Close()
        self.PanelDetailInfo.gameObject:SetActiveEx(true)
        self:UpdateRightElementView()
        self:CloseChildUi(CHILD_UI_EQUIP)
        self:CloseChildUi(CHILD_UI_TEAM)
    elseif self.CurUiType == CharDetailUiType.Equip then
        self.AssetPanel:Open()
        self.PanelDetailInfo.gameObject:SetActiveEx(false)
        self:OpenChildUi(CHILD_UI_EQUIP, self.CharacterId, self)
        self:CloseChildUi(CHILD_UI_TEAM)
    elseif self.CurUiType == CharDetailUiType.Parner then
        self.AssetPanel:Open()
        self.PanelDetailInfo.gameObject:SetActiveEx(false)
        self:CloseChildUi(CHILD_UI_EQUIP)
        self:OpenChildUi(CHILD_UI_TEAM, self.CharacterId, self)
    end
end

function XUiCharacterDetail:UpdateRightElementView()
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(self.CharacterId)
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    if not detailConfig or not charConfig then
        return
    end

    --描述
    self.TxtArchiveTitle.text = charConfig.Name
    self.TxtArchIvesDes.text = detailConfig.DetailDes

    --职业
    local careerConfig = XMVCA.XCharacter:GetNpcTypeTemplate(detailConfig.Career)
    if not careerConfig then
        return
    end
    self.BtnCareer:SetRawImage(careerConfig.Icon)
    self.BtnCareer:SetNameByGroup(0, careerConfig.Name)

    --元素
    local elementValueList = detailConfig.ObtainElementValueList
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local btn = self["BtnElement" .. i]
        if elementList[i] then
            btn.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            btn:SetRawImage(elementConfig.Icon)
            btn:SetNameByGroup(0, elementConfig.ElementName)
            btn:SetNameByGroup(1, elementValueList[i].."%")
        else
            btn.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.CharacterId)
    local isEmpty = XTool.IsTableEmpty(generalSkillIds)
    self.ListGeneralSkillDetail.parent.gameObject:SetActiveEx(not isEmpty)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
            self["BtnGeneralSkill"..i]:SetNameByGroup(0, generalSkillConfig.Name)
        end
    end

    --特点
    local specialTitleList = detailConfig.ObtainSpeicalTitle
    local specialDesList = detailConfig.ObtainSpeicalDes
    for i = 1, 3 do
        if specialTitleList[i] then
            self.TxtSpecialDes[i].text = specialTitleList[i]
            self.Txt[i].text = specialDesList[i]
            self.TxtSpecialDes[i].gameObject:SetActiveEx(true)
            self.Txt[i].gameObject:SetActiveEx(true)
        else
            self.TxtSpecialDes[i].gameObject:SetActiveEx(false)
            self.Txt[i].gameObject:SetActiveEx(false)
        end
    end

    --类型
    -- local graphValueList = detailConfig.AttribGraphNum
    -- local len = #graphValueList
    -- for i = 1, len do
    --     local pointTrans = self.PanelPointRoot:GetChild(i - 1)
    --     local edgePos = self.PanelEdgeRoot:GetChild(i - 1).localPosition
    --     local ratio = graphValueList[i] / 100
    --     pointTrans.localPosition = CS.UnityEngine.Vector3(edgePos.x * ratio, edgePos.y * ratio, 0)
    -- end
    -- self.PanelPointRoot.parent:GetComponent(typeof(CS.XUiPolygon)):Refresh()

    --类型名字
    -- for i = 1, 6 do
    --     local config = self._Control:GetCharGraphTemplate(i)
    --     if config then
    --         self.TxtGraphName[i].text = config.GraphName
    --     end
    -- end

    --人物名字，名称，icon等
    local quality = XMVCA.XCharacter:GetCharMinQuality(self.CharacterId)
    local npcId = XMVCA.XCharacter:GetCharNpcId(self.CharacterId, quality)
    local npc = CS.XNpcManager.GetNpcTemplate(npcId)

    if not npc then
        return
    end

    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality))
    self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(self.CharacterId))
    self.TxtCharacterName.text = charConfig.Name
    self.TxtCharacterDesName.text = charConfig.TradeName

    local castName = XMVCA.XFavorability:GetCharacterCvById(self.CharacterId)
    local cast = (castName ~= "") and CS.XTextManager.GetText("FavorabilityCast")..castName or ""
    self.TxtCV.text = cast

    -- 势力
    local config = XExhibitionConfigs.GetExhibitionGroupByCharId(self.CharacterId)
    local str = config and config.GroupNameEn
    self.TxtGroup.text = string.IsNilOrEmpty(str) and CS.XTextManager.GetText("CharacterExhibitionGroupNullText") or str
end

function XUiCharacterDetail:OnBtnBackClick()
    if self.CurUiType == CharDetailUiType.Parner or self.CurUiType == CharDetailUiType.Equip then
        self:SwitchView(CharDetailUiType.Detail)
        self.Bg.gameObject:SetActiveEx(true)
        self.Bg2.gameObject:SetActiveEx(true)
    else
        -- local tPos = self.PanelContentRtf.anchoredPosition
        -- if tPos.x > -400 then
        --     self.PanelContentRtf.anchoredPosition = CS.UnityEngine.Vector2(-450, tPos.y)
        --     self.BtnArchive.gameObject:SetActiveEx(true)
        --     self.BtnDetial.gameObject:SetActiveEx(false)
        -- else
        -- end
        self:Close()
    end
end

function XUiCharacterDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end