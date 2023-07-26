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
end
-- auto
function XUiCharacterDetail:OnBtnTeamRecomendClick()
    self:SwitchView(CharDetailUiType.Parner)
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
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(CharacterId)
    if not detailConfig then
        return
    end

    self.CharacterId = CharacterId

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.PanelContentRtf = self.PanelContent:GetComponent("RectTransform")
    -- self.BtnArchive.gameObject:SetActiveEx(true)
    self.BtnDetial.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.BtnEquipRecomend.gameObject:SetActiveEx(XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend))

    self:SwitchView(CharDetailUiType.Detail)

end

function XUiCharacterDetail:SwitchView(uiType)
    self.CurUiType = uiType
    self:UpdateStateView()
end


function XUiCharacterDetail:UpdateStateView()
    if self.CurUiType == CharDetailUiType.Detail then
        self.PanelAsset.gameObject:SetActiveEx(false)
        self.PanelDetailInfo.gameObject:SetActiveEx(true)
        self:UpdateRightElementView()
        self:CloseChildUi(CHILD_UI_EQUIP)
        self:CloseChildUi(CHILD_UI_TEAM)
    elseif self.CurUiType == CharDetailUiType.Equip then
        self.PanelAsset.gameObject:SetActiveEx(true)
        self.PanelDetailInfo.gameObject:SetActiveEx(false)
        self:OpenChildUi(CHILD_UI_EQUIP, self.CharacterId, self)
        self:CloseChildUi(CHILD_UI_TEAM)
    elseif self.CurUiType == CharDetailUiType.Parner then
        self.PanelAsset.gameObject:SetActiveEx(true)
        self.PanelDetailInfo.gameObject:SetActiveEx(false)
        self:CloseChildUi(CHILD_UI_EQUIP)
        self:OpenChildUi(CHILD_UI_TEAM, self.CharacterId, self)
    end
end

function XUiCharacterDetail:UpdateRightElementView()
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.CharacterId)
    local charConfig = XCharacterConfigs.GetCharacterTemplate(self.CharacterId)
    if not detailConfig or not charConfig then
        return
    end

    --描述
    self.TxtArchiveTitle.text = charConfig.Name
    self.TxtArchIvesDes.text = detailConfig.DetailDes

    --职业
    local careerConfig = XCharacterConfigs.GetNpcTypeTemplate(detailConfig.Career)
    if not careerConfig then
        return
    end
    self.TxtCareerName.text = careerConfig.Name
    self:SetUiSprite(self.ImgCareerIcon, careerConfig.Icon)

    --元素
    local elementValueList = detailConfig.ObtainElementValueList
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        if elementList[i] then
            self.TxtElementDes[i].gameObject:SetActiveEx(true)
            self.TxtElementValue[i].gameObject:SetActiveEx(true)
            self.TxtElementValue[i].text = string.format("%s%s", elementValueList[i], "%")

            local config = XCharacterConfigs.GetCharElement(elementList[i])
            if config then
                self.TxtElementDes[i].text = config.ElementName
            end
        else
            self.TxtElementDes[i].gameObject:SetActiveEx(false)
            self.TxtElementValue[i].gameObject:SetActiveEx(false)
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
    local graphValueList = detailConfig.AttribGraphNum
    local len = #graphValueList
    for i = 1, len do
        local pointTrans = self.PanelPointRoot:GetChild(i - 1)
        local edgePos = self.PanelEdgeRoot:GetChild(i - 1).localPosition
        local ratio = graphValueList[i] / 100
        pointTrans.localPosition = CS.UnityEngine.Vector3(edgePos.x * ratio, edgePos.y * ratio, 0)
    end
    self.PanelPointRoot.parent:GetComponent(typeof(CS.XUiPolygon)):Refresh()

    --类型名字
    for i = 1, 6 do
        local config = XCharacterConfigs.GetCharGraphTemplate(i)
        if config then
            self.TxtGraphName[i].text = config.GraphName
        end
    end

    --人物名字，名称，icon等
    local quality = XCharacterConfigs.GetCharMinQuality(self.CharacterId)
    local npcId = XCharacterConfigs.GetCharNpcId(self.CharacterId, quality)
    local npc = CS.XNpcManager.GetNpcTemplate(npcId)

    if not npc then
        return
    end

    self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharQualityIcon(quality))
    self.RImgRoleIcon:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyImage(self.CharacterId))
    self.TxtCharacterName.text = charConfig.Name
    self.TxtCharacterDesName.text = charConfig.TradeName

    local castName = XFavorabilityConfigs.GetCharacterCvById(self.CharacterId)
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