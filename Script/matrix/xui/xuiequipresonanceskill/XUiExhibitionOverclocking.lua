-- 超频界面
local XUiExhibitionOverclocking = XLuaUiManager.Register(XLuaUi, "UiExhibitionOverclocking")
local PanelDic = {}

function XUiExhibitionOverclocking:OnAwake()
    self:InitPanels(1)
    self:InitPanels(2)
end

function XUiExhibitionOverclocking:InitPanels(pos)
    local Panel = PanelDic[pos]
    if not Panel then
        Panel = {}
        PanelDic[pos] = Panel
    end
    XTool.InitUiObjectByUi(Panel, self["PanelSkill"..pos]) -- 将3d的内容都加进来

    self:RegisterClickEvent(Panel.BtnLock, function () self:OnBtnLockClick(pos) end)
    self:RegisterClickEvent(Panel.BtnAwake, function () self:OnBtnAwakeClick(pos) end)
    self:RegisterClickEvent(Panel.BtnAwarenessOccupy, function () self:OnBtnAwarenessOccupyClick(pos) end)
end

function XUiExhibitionOverclocking:OnStart(equipId, rootUi)
    self.EquipId = equipId
    self.RootUi = rootUi
end

function XUiExhibitionOverclocking:OnEnable()
    self.EquipId = self.RootUi.EquipId
    self:RefreshByPos(1)
    self:RefreshByPos(2)
end

function XUiExhibitionOverclocking:RefreshData(equipId)
    self.EquipId = equipId
    self:OnEnable()
end

function XUiExhibitionOverclocking:RefreshByPos(pos)
    local Panel = PanelDic[pos]

    local canAwake = XDataCenter.EquipManager.CheckEquipCanAwake(self.EquipId, pos)
    local isAwake = XDataCenter.EquipManager.IsEquipPosAwaken(self.EquipId, pos)
    local equipSite = XDataCenter.EquipManager.GetEquipSite(self.EquipId)
    local awarenessChapterData = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite)
    local isOccupy = awarenessChapterData:IsOccupy()
    -- 显隐
    Panel.PanelLock.gameObject:SetActiveEx(not canAwake)
    Panel.PanelInfo.gameObject:SetActiveEx(canAwake)
    Panel.PanelAwarenessOccupy.gameObject:SetActiveEx(isAwake)
    Panel.BtnAwake.gameObject:SetActiveEx(not isAwake and canAwake)
    Panel.ImgActive.gameObject:SetActiveEx(isOccupy)
    Panel.ImgUnActive.gameObject:SetActiveEx(not isOccupy)
    Panel.ImgActive2.gameObject:SetActiveEx(isAwake)
    Panel.ImgUnActive2.gameObject:SetActiveEx(not isAwake)
    -- 数据
    local characterId = XDataCenter.EquipManager.GetResonanceBindCharacterId(self.EquipId, pos)
    if XTool.IsNumberValid(characterId) then
        Panel.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characterId))
    end

    local descList = XDataCenter.EquipManager.GetAwakeSkillDesList(self.EquipId, pos)
    Panel.TxtSkillDes.text = descList[1] .. "\n" .. descList[2]
    local orgColor = Panel.TxtSkillDes.color
    local alphaValue = isAwake and 1 or 0.6
    Panel.TxtSkillDes.color = CS.UnityEngine.Color(orgColor.r, orgColor.g, orgColor.b, alphaValue)

    local skillInfo = XDataCenter.EquipManager.GetResonanceSkillInfo(self.EquipId, pos)
    Panel.RImgResonanceSkill.gameObject:SetActiveEx(skillInfo.Icon)
    Panel.TxtSkillName.text = skillInfo.Name
    if skillInfo.Icon then
        Panel.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    end
    Panel.TxtPos.text = "0"..pos

    -- 公约加成
    Panel.TxtHarm.text = XDataCenter.EquipManager.GetEquipAwarenessOccupyHarmDesc(self.EquipId, 1)
    local alphaValue2 = isOccupy and 1 or 0.6
    local orgColor2 = Panel.TxtHarm.color
    Panel.TxtHarm.color = CS.UnityEngine.Color(orgColor2.r, orgColor2.g, orgColor2.b, alphaValue2)
end

function XUiExhibitionOverclocking:OnBtnLockClick(pos)
    XUiManager.TipError(CS.XTextManager.GetText("EquipResonancedLimit"))
    XLuaUiManager.SetMask(true) -- 这里打开太慢了 加个遮罩
    self.RootUi.PanelTabGroup:SelectIndex(XEquipConfig.EquipDetailBtnTabIndex.Resonance)
    self.RootUi:OpenOneChildUi("UiEquipResonanceSelect", self.EquipId, self.RootUi)
    self.RootUi:FindChildUiObj("UiEquipResonanceSelect"):Refresh(pos)
    XLuaUiManager.SetMask(false)
end

function XUiExhibitionOverclocking:OnBtnAwakeClick(pos)
    local equipId = self.EquipId

    if not XDataCenter.EquipManager.CheckEquipCanAwake(equipId, pos) then
        XUiManager.TipText("EquipCanNotAwakeCondition")
        return
    end

    self.RootUi:FindChildUiObj("UiEquipResonanceAwake"):Refresh(pos)
    self.RootUi:OpenOneChildUi("UiEquipResonanceAwake", equipId, self.RootUi)
end

function XUiExhibitionOverclocking:OnBtnAwarenessOccupyClick(pos)
    XLuaUiManager.Open("UiAwarenessOccupyPosTips", self.EquipId, pos)
end
