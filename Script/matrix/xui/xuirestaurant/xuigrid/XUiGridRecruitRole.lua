
local XUiGridRecruitRole = XClass(nil, "XUiGridRecruitRole")

function XUiGridRecruitRole:Ctor(ui, onClick)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClick = onClick
    self.GridTags = {}
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

---@param character XRestaurantStaff
--------------------------
function XUiGridRecruitRole:Refresh(character, selectRoleId)
    if not character then
        self.GameObject:SetActiveEx(false)
        return
    end
    local id, level = character:GetProperty("_Id"), character:GetProperty("_Level")
    self.CharacterId = id
    self.IsRecruit = character:GetProperty("_IsRecruit")
    self.RImgHead:SetRawImage(character:GetIcon())
    self.PanelUnlock.gameObject:SetActiveEx(self.IsRecruit)
    self.PanelLock.gameObject:SetActiveEx(not self.IsRecruit)
    self.TxtLevel.gameObject:SetActiveEx(self.IsRecruit)
    self:SetSelect(selectRoleId == self.CharacterId)
    if self.IsRecruit then
        self.TxtLevel.text = character:GetLevelStr()
        self.ImgLabel:SetSprite(XRestaurantConfigs.GetCharacterLevelLabelIcon(level))
    end
    self:RefreshTags(id, self.IsRecruit and level or XRestaurantConfigs.StaffLevel.Low)
end

function XUiGridRecruitRole:RefreshTags(id, level)
    for _, grid in pairs(self.GridTags) do
        grid.GameObject:SetActiveEx(false)
    end
    local skillIds = XRestaurantConfigs.GetCharacterSkillIds(id, level)
    for idx, skillId in pairs(skillIds or {}) do
        local grid = self.GridTags[idx]
        if not grid then
            local ui = idx == 1 and self.GridTag or XUiHelper.Instantiate(self.GridTag, self.PanelTag)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridTags[idx] = grid
        end
        local areaType = XRestaurantConfigs.GetCharacterSkillAreaType(skillId)
        grid.ImgBg:SetSprite(XRestaurantConfigs.GetCharacterSkillLabelIcon(areaType, true))
        grid.TxtTag.text = XRestaurantConfigs.GetCharacterSkillTypeName(areaType)
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