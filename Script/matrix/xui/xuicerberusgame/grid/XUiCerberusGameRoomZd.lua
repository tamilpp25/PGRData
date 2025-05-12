---@class XUiCerberusGameRoomZd
local XUiCerberusGameRoomZd = XClass(nil, "XUiCerberusGameRoomZd")

function XUiCerberusGameRoomZd:Ctor(ui, rootui)
    self.RootUi2D = rootui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiCerberusGameRoomZd:SetData(stageId)
    local xStagePoint = XMVCA.XCerberusGame:GetLastSelectXStoryPoint()
    if not xStagePoint then
        self.GameObject:SetActiveEx(false)
        return
    end

    -- 防止剧情模式点了后又进这
    local xStage = xStagePoint:GetXStage()
    if not xStage or xStage.StageId ~= stageId then
        self.GameObject:SetActiveEx(false)
        return
    end

    local charList = xStagePoint:GetTargetCharacterList()
    if #charList >= 3 or #charList <= 0 then
        self.GameObject:SetActiveEx(false)
        return
    end

    for k, id in pairs(charList) do
        local icon = XMVCA.XCharacter:GetCharBigRoundnessHeadIcon(id)
        self["StandIcon"..k]:SetRawImage(icon)
        self["Head"..k].gameObject:SetActiveEx(true)
    end
end

return XUiCerberusGameRoomZd