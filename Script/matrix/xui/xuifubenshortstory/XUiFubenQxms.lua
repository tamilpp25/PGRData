local XUiGridQxmsRole = require("XUi/XUiFubenShortStory/XUiGridQxmsRole")

---@class XUiFubenQxms : XLuaUi
---@field GridRoleDic XUiGridQxmsRole[]
local XUiFubenQxms = XLuaUiManager.Register(XLuaUi, "UiFubenQxms")

function XUiFubenQxms:OnAwake()
    self:RegisterUiEvents()
    self.GridRoleDic = {}

    self.IsHidden = false
    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiFubenQxms:OnStart(entityIds, stageId, callback)
    self.EntityIds = XTool.Clone(entityIds)
    self.StageId = stageId
    self.CallBack = callback
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    self.RobotIds = stageCfg.RobotId
end

function XUiFubenQxms:OnEnable()
    self:RefreshModel(false)
    self:RefreshRole()
end

function XUiFubenQxms:RefreshModel(isPlayEffect)
    local lastIsHidden = self.IsHidden
    self.IsHidden = false
    for _, id in pairs(self.EntityIds) do
        if not XEntityHelper.GetIsRobot(id) then
            self.IsHidden = true
            break
        end
    end
    if isPlayEffect and lastIsHidden ~= self.IsHidden then
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(true)
    end
    self.TxtNormalMode.gameObject:SetActiveEx(not self.IsHidden)
    self.TxtHiddenMode.gameObject:SetActiveEx(self.IsHidden)
end

function XUiFubenQxms:RefreshRole()
    for i = 1, 3 do
        local entitiyId = self.EntityIds[i] or 0
        local grid = self.GridRoleDic[i]
        if not grid then
            grid = XUiGridQxmsRole.New(self["PanelRole" .. i], self)
            self.GridRoleDic[i] = grid
        end
        grid:Refresh(entitiyId)
    end
end

function XUiFubenQxms:SwitchRole(entitiyId)
    local isContain, index = table.contains(self.EntityIds, entitiyId)
    if not isContain then
        return
    end
    local grid = self.GridRoleDic[index]
    local id
    local isRobot = XEntityHelper.GetIsRobot(entitiyId)
    if isRobot then
        local charId = XRobotManager.GetCharacterId(entitiyId)
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(charId)
        if not isOwn then
            local name = XMVCA.XCharacter:GetCharacterFullNameStr(charId)
            XUiManager.TipMsg(XUiHelper.GetText("NotOwn", name))
            return
        end
        id = charId
    else
        id = self.RobotIds[index]
    end
    self.EntityIds[index] = id
    grid:Refresh(id)
    grid:PlayEffect()
    self:RefreshModel(true)
end

function XUiFubenQxms:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiFubenQxms:OnBtnBackClick()
    self:Close()
end

function XUiFubenQxms:OnBtnConfirmClick()
    self:Close()
    if self.CallBack then
        self.CallBack(self.EntityIds, self.IsHidden)
    end
end

return XUiFubenQxms