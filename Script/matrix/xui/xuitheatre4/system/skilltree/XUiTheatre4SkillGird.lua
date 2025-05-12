---@class XUiTheatre4SkillGird : XUiNode
---@field Icon1 UnityEngine.RectTransform
---@field Icon2 UnityEngine.RectTransform
---@field Icon3 UnityEngine.RectTransform
---@field Icon4 UnityEngine.RectTransform
---@field Icon5 UnityEngine.RectTransform
---@field GridSkill UnityEngine.RectTransform
---@field GirdSkillGroup XUiButtonGroup
---@field GridSkillTop UnityEngine.RectTransform
---@field ProgressImage UnityEngine.UI.Image
---@field Parent XUiTheatre4Skill
local XUiTheatre4SkillGird = XClass(XUiNode, "XUiTheatre4SkillGird")

-- region 生命周期

function XUiTheatre4SkillGird:OnStart()
    self._SkillButtonGroup = {}
    self._SpecialIndex = {
        [1] = true,
        [5] = true,
    }
    self._Entitys = nil

    self:_InitUi()
end

-- endregion

function XUiTheatre4SkillGird:OnSelectSkill(selectIndex)
    self:_ShowSkillPanel(selectIndex)
end

---@param entitys XTheatre4TechEntity[]
function XUiTheatre4SkillGird:Refresh(entitys)
    local buttonGroup = {}
    local unlockNumber = -1

    self._Entitys = entitys
    for index, entity in pairs(entitys) do
        local button = self._SkillButtonGroup[index]
        ---@type XTheatre4TechConfig
        local config = entity:GetConfig()

        if not button then
            local gridObject = nil

            if self._SpecialIndex[index] then
                gridObject = XUiHelper.Instantiate(self.GridSkillTop, self["Icon" .. index])
            else
                gridObject = XUiHelper.Instantiate(self.GridSkill, self["Icon" .. index])
            end

            button = gridObject:GetComponent(typeof(CS.XUiComponent.XUiButton))
            button.transform:Reset()
            self._SkillButtonGroup[index] = button
        end

        local imgUnActive = button.transform:FindTransform("ImgUnActiveBg")

        button.gameObject:SetActiveEx(true)
        button:SetRawImage(config:GetIcon())
        button:ShowReddot(entity:IsShowRedPoint())
        if not entity:IsUnlock() then
            button:ShowTag(true)
            if imgUnActive then
                imgUnActive.gameObject:SetActiveEx(false)
            end
        else
            button:ShowTag(false)
            if not entity:IsActived() then
                if imgUnActive then
                    imgUnActive.gameObject:SetActiveEx(true)
                end
            else
                unlockNumber = unlockNumber + 1
                if imgUnActive then
                    imgUnActive.gameObject:SetActiveEx(false)
                end
            end
        end
        table.insert(buttonGroup, button)
    end
    for i = #entitys + 1, #self._SkillButtonGroup do
        self._SkillButtonGroup[i].gameObject:SetActiveEx(false)
    end

    self.ProgressImage.fillAmount = math.max(unlockNumber, 0) / math.max((#entitys - 1), 1)
    self.GirdSkillGroup:Init(buttonGroup, Handler(self, self.OnSelectSkill))
    self:CancelSelect()
end

function XUiTheatre4SkillGird:CancelSelect()
    self.GirdSkillGroup:CancelSelect()
end

function XUiTheatre4SkillGird:RefreshRedDot()
    if XTool.IsTableEmpty(self._Entitys) then
        return
    end

    local entitys = self._Entitys

    for index, entity in pairs(entitys) do
        local button = self._SkillButtonGroup[index]

        if button then
            button:ShowReddot(entity:IsShowRedPoint())
        end
    end
end

-- region 私有方法

function XUiTheatre4SkillGird:_ShowSkillPanel(selectIndex)
    local entity = self._Entitys[selectIndex]

    self.Parent:ShowTipsPanel(entity, self, self._SpecialIndex[selectIndex])
end

function XUiTheatre4SkillGird:_CloseSkillPanel()
    self.Parent:CloseTipsPanel()
end

function XUiTheatre4SkillGird:_InitUi()
    self.GridSkill.gameObject:SetActiveEx(false)
    self.GridSkillTop.gameObject:SetActiveEx(false)
end

-- endregion

return XUiTheatre4SkillGird
