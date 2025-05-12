local XUiDlcMultiPlayerSkillDesc = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterSkill/XUiDlcMultiPlayerSkillDesc")

---@class XUiDlcMultiPlayerSkill : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field CatSkillDescPanel UnityEngine.RectTransform
---@field MouseSkillDescPanel UnityEngine.RectTransform
---@field BtnYes XUiComponent.XUiButton
local XUiDlcMultiPlayerSkill = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerSkill")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp

function XUiDlcMultiPlayerSkill:OnAwake()
    --变量声明
    ---@type XUiDlcMultiPlayerSkillDesc
    self._CatCamp = XUiDlcMultiPlayerSkillDesc.New(self.CatSkillDescPanel, self, CampEnum.Cat)
    ---@type XUiDlcMultiPlayerSkillDesc
    self._MouseCamp = XUiDlcMultiPlayerSkillDesc.New(self.MouseSkillDescPanel, self, CampEnum.Mouse)
end

function XUiDlcMultiPlayerSkill:OnStart()
    --注册点击事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick, true)

    self.BtnYes:SetName(XUiHelper.GetText("MultiMouseHunterSkillSureChange"))
end

function XUiDlcMultiPlayerSkill:OnEnable()
    --注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA, self._Refresh, self)

    --业务初始化
    self:_Refresh()
end

function XUiDlcMultiPlayerSkill:OnDisable()
    --移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA, self._Refresh, self)
end

-- region 业务逻辑
function XUiDlcMultiPlayerSkill:_Refresh()
    self._CatCamp:Refresh()
    self._MouseCamp:Refresh()
end
-- endregion

-- region 按钮事件
function XUiDlcMultiPlayerSkill:OnBtnCloseClick()
    self:Close()
end

function XUiDlcMultiPlayerSkill:OnBtnYesClick()
    self._Control:RequestDlcMultiplayerSelectSkill(self._CatCamp.CurSelectSkillId, self._MouseCamp.CurSelectSkillId, function()
        self:Close()
    end)
end
-- endregion

return XUiDlcMultiPlayerSkill