local pairs = pairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.white,
}

local XUiGridTRPGRoleDetail = XClass(nil, "XUiGridTRPGRoleDetail")

function XUiGridTRPGRoleDetail:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.TalentGrids = {}

    XTool.InitUiObject(self)
end

function XUiGridTRPGRoleDetail:Refresh(roleId, showBuffEffect)
    if self.TxtName then
        local roleName = XTRPGConfigs.GetRoleName(roleId)
        self.TxtName.text = roleName
    end

    if self.RImgHead then
        local roleIcon = XTRPGConfigs.GetRoleHeadIcon(roleId)
        self.RImgHead:SetRawImage(roleIcon)
    end

    if self.PanelUp then
        local isUp = XDataCenter.TRPGManager.IsRoleHaveBuffUp(roleId)
        self.PanelUp.gameObject:SetActiveEx(isUp)
    end

    if self.PanelDown then
        local isDown = XDataCenter.TRPGManager.IsRoleHaveBuffDown(roleId)
        self.PanelDown.gameObject:SetActiveEx(isDown)
    end

    local attributes = XDataCenter.TRPGManager.GetRoleAttributes(roleId)
    for index, attr in pairs(attributes) do

        local img = self["ImgAttr" .. index]
        if img then
            local attrIcon = XTRPGConfigs.GetRoleAttributeIcon(attr.Type)
            self.RootUi:SetUiSprite(img, attrIcon)

            if showBuffEffect then
                local isDown = XDataCenter.TRPGManager.IsRoleHaveBuffDown(roleId)
                img.color = CONDITION_COLOR[isDown]
            end
        end

        local textAttr = self["TxtAttr" .. index]
        if textAttr then
            textAttr.text = attr.Value

            if showBuffEffect then
                local isDown = XDataCenter.TRPGManager.IsRoleHaveBuffDown(roleId)
                textAttr.color = CONDITION_COLOR[isDown]
            end
        end

    end

    if self.TxtTalent and self.PanelTalent then
        self.TxtTalent.gameObject:SetActiveEx(false)
        local talentIds = XDataCenter.TRPGManager.GetRoleCommonTalentIds(roleId)
        for index, talentId in pairs(talentIds) do
            local grid = self.TalentGrids[index]
            if not grid then
                local ui = index == 1 and self.TxtTalent or CSUnityEngineObjectInstantiate(self.TxtTalent.gameObject, self.PanelTalent)
                grid = {
                    GameObject = ui.gameObject,
                    Transform = ui.transform,
                }
                XTool.InitUiObject(grid)
                self.TalentGrids[index] = grid
            end
            grid.Txt.text = XTRPGConfigs.GetRoleTalentDescription(roleId, talentId)
            grid.GameObject:SetActiveEx(true)
        end

        for i = #talentIds + 1, #self.TalentGrids do
            local grid = self.TalentGrids[i]
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiGridTRPGRoleDetail