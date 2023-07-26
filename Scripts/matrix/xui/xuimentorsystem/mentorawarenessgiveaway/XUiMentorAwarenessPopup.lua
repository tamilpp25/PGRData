local XUiMentorAwarenessPopup = XLuaUiManager.Register(XLuaUi, "UiMentorAwarenessPopup")
local XUiGridEquip = require("XUi/XUiEquipAwarenessReplace/XUiGridEquip")
local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_AWARENESS_ATTR_COUNT = 2
local ButtonState = {
    Select = 1,
    UnSelect = 2,
    }
local ButtonName = {
    [1] = CSXTextManagerGetText("MentorSelectStudentGiveText"),
    [2] = CSXTextManagerGetText("MentorUnSelectStudentGiveText"),
}
function XUiMentorAwarenessPopup:OnAwake()
    self:AutoAddListener()
end

function XUiMentorAwarenessPopup:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiMentorAwarenessPopup:OnEnable()
    self.EquipId = self.RootUi.SelectEquipId
    self:Refresh()
    if self.RootUi.BtnClosePopup then
        self.RootUi.BtnClosePopup.gameObject:SetActiveEx(true)
    end
end

function XUiMentorAwarenessPopup:OnDisable()
    if self.RootUi.BtnClosePopup then
        self.RootUi.BtnClosePopup.gameObject:SetActiveEx(false)
    end
end

function XUiMentorAwarenessPopup:Refresh()
    self.UsingAttrMap = XDataCenter.EquipManager.GetEquipAttrMap(self.EquipId)
    self:UpdateUsingPanel()
end


function XUiMentorAwarenessPopup:UpdateUsingPanel()
    if not self.UsingEquipGrid then
        self.UsingEquipGrid = XUiGridEquip.New(self.GridEquipUsing, self, nil, true)
        self.UsingEquipGrid:InitRootUi(self)
    end
    self.UsingEquipGrid:Refresh(self.EquipId)

    local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self.TxtName.text = XDataCenter.EquipManager.GetEquipName(equip.TemplateId)

    local attrCount = 1
    local attrMap = self.UsingAttrMap
    for _, attrInfo in pairs(attrMap or {}) do
        if attrCount > MAX_AWARENESS_ATTR_COUNT then break end

        self["TxtUsingAttrName" .. attrCount].text = attrInfo.Name
        self["TxtUsingAttrValue" .. attrCount].text = attrInfo.Value
        self["PanelUsingAttr" .. attrCount].gameObject:SetActiveEx(true)

        attrCount = attrCount + 1
    end
    for i = attrCount, MAX_AWARENESS_ATTR_COUNT do
        self["PanelUsingAttr" .. i].gameObject:SetActiveEx(false)
    end
    
    --是否激活颜色不同
    local suitId = XDataCenter.EquipManager.GetSuitId(equip.Id)
    local skillDesList = XDataCenter.EquipManager.GetSuitActiveSkillDesList(suitId, 0)

    for i = 1, XEquipConfig.MAX_SUIT_SKILL_COUNT do
        local componentText = self["TxtSkillDes" .. i]
        if not skillDesList[i] then
            componentText.gameObject:SetActiveEx(false)
        else
            componentText.text = skillDesList[i].SkillDes
            componentText.gameObject:SetActiveEx(true)
        end
    end
    
    self:CheckButtonState()
    local IsUnSelect = self.CurButtonState == ButtonState.UnSelect
    self.BtnGift:SetName(ButtonName[self.CurButtonState])
    self.BtnGift.gameObject:SetActiveEx(IsUnSelect or (not IsUnSelect and #self.RootUi.SelectedEquipIdList < 2))
end

function XUiMentorAwarenessPopup:CheckButtonState()
    self.CurButtonState = ButtonState.Select
    for index,id in pairs(self.RootUi.SelectedEquipIdList or {}) do
        if self.EquipId == id then
            self.SelectIndex = index
            self.CurButtonState = ButtonState.UnSelect
            break
        end
    end
end

function XUiMentorAwarenessPopup:AutoAddListener()
    self.BtnGift.CallBack = function()
        self:OnBtnGiftClick()
    end
end

function XUiMentorAwarenessPopup:OnBtnGiftClick()
    if self.CurButtonState == ButtonState.UnSelect then
        table.remove(self.RootUi.SelectedEquipIdList,self.SelectIndex)
    else
        table.insert(self.RootUi.SelectedEquipIdList,self.EquipId)
    end
    
    self.RootUi:UpdateCurEquipGrids()
    self.RootUi:OnSelectSortType(XEquipConfig.PriorSortType.Star, true, true)
end