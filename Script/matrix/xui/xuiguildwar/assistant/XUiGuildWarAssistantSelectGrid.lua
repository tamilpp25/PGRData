---@class XUiGuildWarAssistantSelectGrid
local XUiGuildWarAssistantSelectGrid = XClass(nil, "XUiGuildWarAssistantSelectGrid")

function XUiGuildWarAssistantSelectGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param entity XRobot
function XUiGuildWarAssistantSelectGrid:SetData(entity)
    local characterViewModel = entity:GetCharacterViewModel()
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
        if self["RImgElement" .. i] then
            self["RImgElement" .. i].gameObject:SetActiveEx(elementIcon ~= nil)
            if elementIcon then
                self["RImgElement" .. i]:SetRawImage(elementIcon)
            end
        end
    end
    self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))
    if self.RImgTypeIcon then
        self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    end
    self.ImgInTeam.gameObject:SetActiveEx(false)
end

function XUiGuildWarAssistantSelectGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

return XUiGuildWarAssistantSelectGrid
