local XUiGridAwarenessOccupyProgress = XClass(nil, "XUiGridAwarenessOccupyProgress")
local Color = 
{
    Active = "0F70BC",
    UnActive = "656565"
}

function XUiGridAwarenessOccupyProgress:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.Button, self.OnButtonClick)
end

function XUiGridAwarenessOccupyProgress:Refresh(chapterId)
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataById(chapterId)
    self.ChapterId = chapterId
    self.ChapterData = data

    local isOccupy = data:IsOccupy()
    local color = isOccupy and Color.Active or Color.UnActive
    self.ImgBgTag.color = XUiHelper.Hexcolor2Color(color)
    self.TxtMarkUp.color = XUiHelper.Hexcolor2Color(color)

    self.PanelHead.gameObject:SetActiveEx(isOccupy)
    self.TxtNumber.text = CS.XTextManager.GetText("AwarenessTfPos", data:GetChapterOrder())
    if isOccupy then
        self.StandIcon:SetRawImage(data:GetOccupyCharacterIcon())
    end

    -- 超频进度、伤害加成
    local equipId = XMVCA.XEquip:GetCharacterEquipId(self.RootUi.CharacterId, data:GetChapterOrder())
    local curr = 0
    local desc = ""
    if XTool.IsNumberValid(equipId) and isOccupy then
        local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(equipId)
        for pos = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
            local bindCharId = equip:GetResonanceBindCharacterId(pos)
            local awaken = equip:IsEquipPosAwaken(pos)
            if awaken and bindCharId ~= 0 and bindCharId == equip.CharacterId then
                curr = curr + 1
            end
        end

        if curr > 0 then
            local attrDesc = self.RootUi._Control:GetEquipAwakeAwarenessAttrDesc(equip.TemplateId)
            local attrValue = self.RootUi._Control:GetEquipAwakeAwarenessAttrValue(equip.TemplateId)
            desc = attrDesc .. (curr * attrValue).."%"
        end
    end

    self.TxtMarkUp.text = desc
    self.TxtProgress.text = XUiHelper.GetText("RpgTowerChallengeCountStr", curr, 2)
    self.TxtMarkUp.gameObject:SetActiveEx(curr > 0)
end

function XUiGridAwarenessOccupyProgress:OnButtonClick()
    if self.ChapterData:CanAssign() then
        XLuaUiManager.Open("UiAwarenessOccupy", self.ChapterData:GetId())
    else
        XDataCenter.FubenAwarenessManager.OpenUi(function ()
            XLuaUiManager.Open("UiAwarenessMainDetail", self.ChapterData:GetId())
        end)
    end

end

return XUiGridAwarenessOccupyProgress