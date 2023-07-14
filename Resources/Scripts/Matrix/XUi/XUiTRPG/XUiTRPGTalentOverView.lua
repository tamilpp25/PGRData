local XUiGridTRPGRoleDetail = require("XUi/XUiTRPG/XUiGridTRPGRoleDetail")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiTRPGTalentOverView = XLuaUiManager.Register(XLuaUi, "UiTRPGTalentOverView")

function XUiTRPGTalentOverView:OnAwake()
    self:AutoAddListener()
end

function XUiTRPGTalentOverView:OnStart()
    self.RoleGrids = {}
end

function XUiTRPGTalentOverView:OnEnable()
    self:UpdateRoles()
end

function XUiTRPGTalentOverView:UpdateRoles()
    local roleIds = XDataCenter.TRPGManager.GetOwnRoleIds()
    if XTool.IsTableEmpty(roleIds) then
        XLog.Error("XUiTRPGTalentOverView:UpdateRoles error: 调查员数据不存在")
        self:Close()
        return
    end

    for index, roleId in ipairs(roleIds) do
        local grid = self.RoleGrids[index]
        if not grid then
            local ui = index == 1 and self.GridTreasureGrade or CSUnityEngineObjectInstantiate(self.GridTreasureGrade, self.PanelGradeContent)
            grid = XUiGridTRPGRoleDetail.New(ui, self)
            self.RoleGrids[index] = grid
        end
        grid:Refresh(roleId)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #roleIds + 1, #self.RoleGrids do
        local grid = self.RoleGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiTRPGTalentOverView:AutoAddListener()
    self:RegisterClickEvent(self.BtnMask, self.OnBtnBackClick)
end

function XUiTRPGTalentOverView:OnBtnBackClick()
    self:Close()
end