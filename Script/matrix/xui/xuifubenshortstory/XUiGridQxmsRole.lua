---@class XUiGridQxmsRole
---@field RawImage UnityEngine.UI.RawImage
---@field BtnSel XUiComponent.XUiButton
local XUiGridQxmsRole = XClass(nil, "XUiGridQxmsRole")

---@param rootUi XUiFubenQxms
function XUiGridQxmsRole:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()

    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiGridQxmsRole:Refresh(entityId)
    self.EntityId = entityId
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if not viewModel then
        self:RefreshUiActive(false)
        return
    end
    self:RefreshUiActive(true)
    -- 头像
    self.RawImage:SetRawImage(viewModel:GetSmallHeadIcon())
    -- 名字
    self.TextName.text = viewModel:GetLogName()
    -- 战力
    self.TextJinengName.text = viewModel:GetAbility()
    -- 试玩
    self.IsRobot = XEntityHelper.GetIsRobot(entityId)
    self.PanelTry.gameObject:SetActiveEx(self.IsRobot)
    -- 按钮提示
    local name = self.IsRobot and "UiFubenQxmsSwitchOwnRole" or "UiFubenQxmsSwitchRobotRole"
    self.BtnSel:SetName(XUiHelper.GetText(name))
    -- 图标
    local icon = self.IsRobot and XFubenConfigs.GetQxmsTryIcon() or XFubenConfigs.GetQxmsUseIcon()
    self.BtnSel:SetRawImage(icon)
end

function XUiGridQxmsRole:RefreshUiActive(value)
    self.Ena.gameObject:SetActiveEx(value)
    self.BtnSel.gameObject:SetActiveEx(value)
    self.Dis.gameObject:SetActiveEx(not value)
end

function XUiGridQxmsRole:PlayEffect()
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

---@return XCharacterViewModel
function XUiGridQxmsRole:GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XMVCA.XCharacter:GetCharacter(id)
        end
        if entity == nil then
            XLog.Warning(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end

function XUiGridQxmsRole:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSel, self.OnBtnSelClick)
end

function XUiGridQxmsRole:OnBtnSelClick()
    self.RootUi:SwitchRole(self.EntityId)
end

return XUiGridQxmsRole