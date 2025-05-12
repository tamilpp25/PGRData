local XUiDlcMultiPlayerSkillDescGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterSkill/XUiDlcMultiPlayerSkillDescGrid")

---@class XUiDlcMultiPlayerSkillDesc : XLuaUi
---@field TxtTitle UnityEngine.UI.Text
---@field SkillContent UnityEngine.RectTransform
---@field SkillGrid UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtDes UnityEngine.UI.Text
local XUiDlcMultiPlayerSkillDesc = XClass(XUiNode, "XUiDlcMultiPlayerSkillDesc")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp

function XUiDlcMultiPlayerSkillDesc:OnStart(camp)
    self._CurCamp = camp
    self._SkillGridUi = {}
    self._CurSkillGridUi = nil
    self._SkillGroupConfig = nil
    self._OnSkillBtnClick = Handler(self, self.OnSkillBtnClick)
    self.CurSelectSkillId = -1

    local _, skillDatas = self._Control:TryGetSkillData()
    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()

    if self._CurCamp == CampEnum.Cat then --猫技能
        self.CurSelectSkillId = skillDatas.SelectCatSkillId
        self._SkillGroupConfig = self._Control:GetDlcMultiplayerSkillGroupConfigById(activityConfig.CatSkillGroup)
        self.TxtTitle.text = XUiHelper.GetText("MultiMouseHunterSkillCatTitle")
    elseif self._CurCamp == CampEnum.Mouse then --鼠技能
        self.CurSelectSkillId = skillDatas.SelectMouseSkillId
        self._SkillGroupConfig = self._Control:GetDlcMultiplayerSkillGroupConfigById(activityConfig.MouseSkillGroup)
        self.TxtTitle.text = XUiHelper.GetText("MultiMouseHunterSkillMouseTitle")
    end
    self:Refresh()
end

function XUiDlcMultiPlayerSkillDesc:Refresh()
    for index, skillId in ipairs(self._SkillGroupConfig.SkillIdList) do
        local ui = self._SkillGridUi[index]
        if not ui then
            local grid = index == 1 and self.SkillGrid or XUiHelper.Instantiate(self.SkillGrid.gameObject, self.SkillContent)
            ui = XUiDlcMultiPlayerSkillDescGrid.New(grid, self)
            self._SkillGridUi[index] = ui
        end
        ui:Refresh(skillId, self._OnSkillBtnClick)

        if skillId == self.CurSelectSkillId then
            self:_SelectSkillDescGrid(ui)
        end
    end
end

function XUiDlcMultiPlayerSkillDesc:_SelectSkillDescGrid(gridUi)
    if self._CurSkillGridUi then
        self._CurSkillGridUi:UnSelect()
    end
    gridUi:Select()
    local skillConfig = gridUi:GetSkillConfig()
    self._CurSkillGridUi = gridUi
    self.CurSelectSkillId = skillConfig.Id
    self.TxtName.text = skillConfig.Name
    self.TxtDes.text = skillConfig.Des
end

function XUiDlcMultiPlayerSkillDesc:OnSkillBtnClick(gridUi)
    self:_SelectSkillDescGrid(gridUi)
end

return XUiDlcMultiPlayerSkillDesc