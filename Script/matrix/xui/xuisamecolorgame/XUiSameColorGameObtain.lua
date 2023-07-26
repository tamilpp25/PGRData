--######################## XUiRoleGrid ########################
local XUiRoleGrid = XClass(nil, "XUiRoleGrid")

function XUiRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiRoleGrid:SetData(role)
    self.RImgHeadIcon:SetRawImage(role:GetCharacterViewModel():GetSmallHeadIcon())
end

--######################## XUiSameColorGameObtain ########################
local XUiSameColorGameObtain = XLuaUiManager.Register(XLuaUi, "UiSameColorGameObtain")

function XUiSameColorGameObtain:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.GridRole.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiSameColorGameObtain:OnStart(roles)
    self.SameColorGameManager.SetIsFirstOpenRoleObtainUi()
    local go, roleGrid
    for _, role in ipairs(roles) do
        go = CS.UnityEngine.Object.Instantiate(self.GridRole, self.PanelContent)
        go.gameObject:SetActiveEx(true)
        roleGrid = XUiRoleGrid.New(go)
        roleGrid:SetData(role)
    end
end

function XUiSameColorGameObtain:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
end

return XUiSameColorGameObtain