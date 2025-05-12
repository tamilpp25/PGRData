---@class XUiGridRecruitRole : XUiNode
---@field _Control XRestaurantControl
local XUiGridRecruitRole = XClass(XUiNode, "XUiGridRecruitRole")

function XUiGridRecruitRole:OnStart(onClick)
    self.OnClick = onClick
    self.GridTags = {}
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
end

---@param character XRestaurantStaffVM
--------------------------
function XUiGridRecruitRole:Refresh(character, selectRoleId)
    if not character then
        self.GameObject:SetActiveEx(false)
        return
    end
    local id, level = character:GetCharacterId(), character:GetLevel()
    self.CharacterId = id
    self.IsRecruit = character:IsRecruit()
    self.RImgHead:SetRawImage(character:GetIcon())
    self.PanelUnlock.gameObject:SetActiveEx(self.IsRecruit)
    self.PanelLock.gameObject:SetActiveEx(not self.IsRecruit)
    self.TxtLevel.gameObject:SetActiveEx(self.IsRecruit)
    self:SetSelect(selectRoleId == self.CharacterId)
    if self.IsRecruit then
        self.TxtLevel.text = character:GetLevelStr()
        self.ImgLabel:SetSprite(character:GetCharacterLevelLabelIcon())
    end
    self:RefreshTags(id, self.IsRecruit and level or XMVCA.XRestaurant.StaffLevelRange.Low)
end

function XUiGridRecruitRole:RefreshTags(id, level)
    for _, grid in pairs(self.GridTags) do
        grid.GameObject:SetActiveEx(false)
    end
    local character = self._Control:GetCharacter(id)
    local skillIds = character:GetSkillIdsInPreview(level)
    for idx, skillId in pairs(skillIds) do
        local grid = self.GridTags[idx]
        if not grid then
            local ui = idx == 1 and self.GridTag or XUiHelper.Instantiate(self.GridTag, self.PanelTag)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridTags[idx] = grid
        end
        local areaType = character:GetCharacterSkillAreaType(skillId)
        grid.ImgBg:SetSprite(character:GetCharacterSkillLabelIcon(areaType, true))
        grid.TxtTag.text = character:GetCharacterSkillTypeName(areaType)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiGridRecruitRole:SetSelect(select)
    self.IsSelect = select
    self.ImgNormal.gameObject:SetActiveEx(not select and self.IsRecruit)
    self.ImgSelect.gameObject:SetActiveEx(select)
    self.ImgDisable.gameObject:SetActiveEx(not select and not self.IsRecruit)
end

function XUiGridRecruitRole:OnBtnClick()
    if not XTool.IsNumberValid(self.CharacterId) then
        return
    end

    if self.IsSelect then
        return
    end
    
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end

return XUiGridRecruitRole