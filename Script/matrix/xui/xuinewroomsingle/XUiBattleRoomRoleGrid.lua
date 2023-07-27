local XGridCharacterV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterV2P6")
---@class XUiBattleRoomRoleGrid : XGridCharacterV2P6
local XUiBattleRoomRoleGrid = XClass(XGridCharacterV2P6, "XUiBattleRoomRoleGrid")

-- function XUiBattleRoomRoleGrid:Ctor(ui)
--     self.GameObject = ui.gameObject
--     self.Transform = ui.transform
--     XTool.InitUiObject(self)
-- end

---@param characterViewModel XCharacterViewModel
function XUiBattleRoomRoleGrid:SetCharacterViewModel(characterViewModel)
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    if self.TxtLevel then
        self.TxtLevel.text = characterViewModel:GetLevel()
    end
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    -- 元素图标
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 3 do
        elementIcon = obtainElementIcons[i]
        local elementImg = self["RImgElement" .. i] or self["RImgCharElement" .. i]
        if elementImg then
            elementImg.gameObject:SetActiveEx(elementIcon ~= nil)
            if elementIcon then
                elementImg:SetRawImage(elementIcon)
            end
        end
    end
    
    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))
    end
    
    if self.RImgTypeIcon then
        self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    end
    -- 独域图标
    if self.PanelUniframe then
        local isUniframe = self.CharacterAgency:GetIsIsomer(characterViewModel:GetId())
        self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
    end

    -- 初始品质
    if self.PanelInitQuality then
        self.PanelInitQuality.gameObject:SetActiveEx(true)
        local initQuality = self.CharacterAgency:GetCharacterInitialQuality(characterViewModel:GetId())
        local icon = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
        self.ImgInitQuality:SetSprite(icon)
    end
end

function XUiBattleRoomRoleGrid:SetData(entity)
    self.Character = entity
    local characterViewModel = entity:GetCharacterViewModel()
    self:SetCharacterViewModel(characterViewModel)
end

-- 拟真常驻角色会覆盖掉试玩角色标签
function XUiBattleRoomRoleGrid:SetGuildFixedRobot(value)
    if self.PanelTryGuildFixedRobot then
        self.PanelTryGuildFixedRobot.gameObject:SetActiveEx(value)
    end
    if value then
        self.PanelTry.gameObject:SetActiveEx(false)
    end
end

function XUiBattleRoomRoleGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetInSameStatus(value)
    self.PanelSameRole.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetLockStatus(value)
    self.ImgLock.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetAbility(value)
    self.TxtPower.text = value
end

return XUiBattleRoomRoleGrid