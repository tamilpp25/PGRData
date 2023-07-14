---@class XUi2023YuanXiaoRoomSkill
local XUi2023YuanXiaoRoomSkill = XClass(nil, "XUi2023YuanXiaoRoomSkill")

function XUi2023YuanXiaoRoomSkill:Ctor(ui)
    self._PlayerId = false
    self._PlayerData = false
    self._Skill = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUi2023YuanXiaoRoomSkill:Update(playerData)
    local playerId = playerData and playerData.Id
    self._PlayerData = playerData
    self._PlayerId = playerId
    local skill = XDataCenter.FubenSpecialTrainManager.GetYuanXiaoSkill(playerId)
    if skill then
        if self._Skill ~= skill and self._Skill and self.PanelEffect then
            self.PanelEffect.gameObject:SetActiveEx(false)
            self.PanelEffect.gameObject:SetActiveEx(true)
        end
        self._Skill = skill
        self.RImgType.gameObject:SetActiveEx(true)
        self.RImgType:SetRawImage(skill.Icon)
    else
        self.RImgType.gameObject:SetActiveEx(false)
    end
end

function XUi2023YuanXiaoRoomSkill:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
        local playerData = self._PlayerData
        if not playerData or playerData.State == XDataCenter.RoomManager.PlayerState.Ready then
            XUiManager.TipText("OnlineCancelReadyBeforeSelectCharacter")
            return
        end
        if XPlayer.Id == self._PlayerId then
            XLuaUiManager.Open("Ui2023YuanXiaoRoomsceneChoice")
        end
    end)
end

return XUi2023YuanXiaoRoomSkill